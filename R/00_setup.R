## R/00_setup.R -----------------------------------------------------------
## Libraries, paths, and helper functions shared by every other script.
## Sourced at the top of 01-05 and by the qmd files.
## -------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(here)
  library(httr2)
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(readr)
  library(stringr)
  library(digest)
})

## --- paths ---------------------------------------------------------------

PATHS <- list(
  raw       = here("data", "raw"),
  processed = here("data", "processed"),
  crosswalk = here("data", "crosswalk"),
  docs      = here("docs")
)
invisible(lapply(PATHS, dir.create, recursive = TRUE, showWarnings = FALSE))

MANIFEST <- file.path(PATHS$raw, "MANIFEST.csv")

## --- credentials ---------------------------------------------------------

## The Census key lives in .Renviron as CENSUS_API_KEY and is never written to
## any file, log or cached pull. Fail loudly and early if it is missing.
census_key <- function() {
  key <- Sys.getenv("CENSUS_API_KEY")
  if (!nzchar(key)) {
    stop(
      "CENSUS_API_KEY is not set.\n",
      "  1. Get a key: https://api.census.gov/data/key_signup.html\n",
      "  2. cp .Renviron.example .Renviron\n",
      "  3. Put CENSUS_API_KEY=<your key> in .Renviron\n",
      "  4. Restart R.\n",
      "Do not paste the key into any script or into the chat.",
      call. = FALSE
    )
  }
  key
}

## Called at source() time so a missing key stops Phase 1 immediately rather
## than halfway through a pull.
invisible(census_key())

## --- manifest ------------------------------------------------------------

## Record provenance for one cached raw file. Idempotent: re-registering the
## same path replaces its row.
manifest_add <- function(path, source_url) {
  stopifnot(file.exists(path))
  row <- tibble(
    file       = fs_relative(path),
    source_url = source_url,
    pulled_at  = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    sha256     = digest(path, algo = "sha256", file = TRUE)
  )
  cur <- if (file.exists(MANIFEST)) {
    read_csv(MANIFEST, col_types = cols(.default = col_character()))
  } else {
    row[0, ]
  }
  out <- bind_rows(filter(cur, .data$file != row$file), row) |> arrange(.data$file)
  write_csv(out, MANIFEST)
  invisible(out)
}

## Path relative to the project root, so the manifest is portable.
fs_relative <- function(path) {
  root <- here()
  sub(paste0("^", normalizePath(root, mustWork = FALSE), "/?"), "",
      normalizePath(path, mustWork = FALSE))
}

## --- generic cached pull -------------------------------------------------

## Run `fetch()` once, save the result to data/raw/<name>, register it in the
## MANIFEST, and on later calls read the cached copy instead of the network.
##
##   fetch      function of no arguments returning a data frame (for .csv) or
##              any R object (for .rds)
##   name       file name under data/raw/, extension .csv or .rds
##   source_url URL recorded in the manifest
##   refresh    TRUE to force a re-pull
cache_pull <- function(name, source_url, fetch, refresh = FALSE) {
  path <- file.path(PATHS$raw, name)
  ext  <- tolower(tools::file_ext(name))
  if (!ext %in% c("csv", "rds", "json")) {
    stop("cache_pull() handles .csv, .rds and .json; got: ", name, call. = FALSE)
  }
  if (file.exists(path) && !refresh) {
    message("cached: ", name)
  } else {
    message("pulling: ", name, "  <- ", source_url)
    obj <- fetch()
    switch(ext,
      csv  = write_csv(obj, path),
      rds  = saveRDS(obj, path),
      json = writeLines(obj, path)
    )
    manifest_add(path, source_url)
  }
  switch(ext,
    csv  = read_csv(path, col_types = cols(.default = col_character()), progress = FALSE),
    rds  = readRDS(path),
    json = readLines(path, warn = FALSE)
  )
}

## --- Socrata -------------------------------------------------------------

SOCRATA_HOST <- "https://data.ny.gov"

## One SoQL request against a Socrata dataset. Always pass an explicit
## $select/$group where the underlying table is large: per CLAUDE.md rule 3 we
## pull aggregates, not whole tables.
##
##   dataset  four-four id, e.g. "ny73-2j3u"
##   query    named list of SoQL parameters WITHOUT the leading $, e.g.
##            list(select = "county, sum(taxable_sales)", group = "county")
socrata_get <- function(dataset, query = list(), host = SOCRATA_HOST,
                        max_rows = 50000L) {
  q <- query
  if (is.null(q$limit)) q$limit <- max_rows
  names(q) <- paste0("$", names(q))
  req <- request(sprintf("%s/resource/%s.json", host, dataset)) |>
    req_url_query(!!!q) |>
    req_user_agent("albany-sales-tax research (R/httr2)") |>
    req_retry(max_tries = 4) |>
    req_timeout(180)
  resp <- req_perform(req)
  out  <- resp_body_string(resp) |> fromJSON(flatten = TRUE)
  if (length(out) == 0 || (is.data.frame(out) && nrow(out) == 0)) {
    return(tibble())
  }
  as_tibble(out)
}

## Socrata's dataset metadata endpoint: the human "about" page is JS-rendered,
## so column names and types come from here.
socrata_meta <- function(dataset, host = SOCRATA_HOST) {
  request(sprintf("%s/api/views/%s.json", host, dataset)) |>
    req_user_agent("albany-sales-tax research (R/httr2)") |>
    req_retry(max_tries = 4) |>
    req_perform() |>
    resp_body_string() |>
    fromJSON(flatten = TRUE)
}

## Tidy column list from socrata_meta(): field name, display name, type.
socrata_cols <- function(meta) {
  cols <- meta$columns
  tibble(
    field    = cols$fieldName,
    label    = cols$name,
    type     = cols$dataTypeName,
    desc     = if (!is.null(cols$description)) cols$description else NA_character_
  )
}

## --- Census --------------------------------------------------------------

## Thin wrapper over the Census API. `censusapi::getCensus()` is used for the
## routine pulls; this exists for endpoints where we need the raw response or
## the variables/geography metadata.
##
##   path  e.g. "2022/ecnbasic" or "2023/acs/acs5"
##   query named list of query parameters (get, for, in, ...)
census_get <- function(path, query = list(), key = census_key()) {
  q <- c(query, list(key = key))
  req <- request(sprintf("https://api.census.gov/data/%s", path)) |>
    req_url_query(!!!q) |>
    req_user_agent("albany-sales-tax research (R/httr2)") |>
    req_retry(max_tries = 4) |>
    req_timeout(180)
  raw <- req_perform(req) |> resp_body_string()
  m <- fromJSON(raw, simplifyVector = TRUE)
  ## Census returns a matrix whose first row is the header.
  out <- as_tibble(m[-1, , drop = FALSE], .name_repair = "minimal")
  names(out) <- m[1, ]
  out
}

## Metadata for a Census dataset: variables.json / geography.json.
census_meta <- function(path, what = c("variables", "geography")) {
  what <- match.arg(what)
  request(sprintf("https://api.census.gov/data/%s/%s.json", path, what)) |>
    req_user_agent("albany-sales-tax research (R/httr2)") |>
    req_retry(max_tries = 4) |>
    req_perform() |>
    resp_body_string() |>
    fromJSON(flatten = TRUE)
}

## --- misc ----------------------------------------------------------------

## Albany identifiers, verified in Phase 1 and used throughout.
IDS <- list(
  state_fips        = "36",
  county_fips       = "001",          # Albany County
  county_fips_full  = "36001",
  place_fips        = "01000",        # Albany city
  place_fips_full   = "3601000"
)

## Append a section to docs/data-layouts.md.
layout_note <- function(title, body) {
  f <- file.path(PATHS$docs, "data-layouts.md")
  cat("\n## ", title, "\n\n", body, "\n", sep = "", file = f, append = TRUE)
  invisible(f)
}

message("00_setup.R loaded. Census key found. Project root: ", here())
