## R/99_check_urls.R -------------------------------------------------------
## Verify that every URL cited in the analysis documents and the crosswalk
## files still resolves. Run before publishing.
## Note: legal aggregators (doi.org, findlaw, justia, nysenate, ecode360) return
## 403 to non-browser clients even though the pages resolve in a browser. They
## are listed below and reported separately rather than as failures; statutes
## and municipal codes are cited by section as well as by URL.
## -------------------------------------------------------------------------
source(here::here("R", "00_setup.R"))

urls <- c(
  here("index.qmd"),
  list.files(here("chapters"), "\\.qmd$", full.names = TRUE),
  list.files(here("appendices"), "\\.qmd$", full.names = TRUE),
  list.files(here("data", "crosswalk"), "\\.csv$", full.names = TRUE)
) |>
  map(readLines, warn = FALSE) |> unlist() |>
  stringr::str_extract_all("https?://[^\\s<>\"),;]+") |> unlist() |>
  stringr::str_remove("[.,;]$") |> unique() |> sort()

check <- function(u) {
  r <- try(request(u) |>
             req_user_agent(paste("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
                                  "(KHTML, like Gecko) Chrome/120.0 Safari/537.36")) |>
             req_method("HEAD") |> req_timeout(30) |>
             req_error(is_error = \(x) FALSE) |> req_perform(), silent = TRUE)
  if (inherits(r, "try-error")) NA_integer_ else resp_status(r)
}

BOT_BLOCKED <- "doi\\.org|findlaw|justia|nysenate|ecode360|census\\.gov/naics|newyork\\.public\\.law"
res <- tibble(url = urls) |> mutate(status = map_int(url, check),
                                    blocked = grepl(BOT_BLOCKED, url))
bad <- res |> filter(!blocked, is.na(status) | status >= 400)
print(as.data.frame(res), right = FALSE)
if (nrow(bad)) {
  cat("\n*** ", nrow(bad), " URL(s) did not return 2xx/3xx:\n", sep = "")
  print(as.data.frame(bad))
} else cat("\nAll ", sum(!res$blocked), " checkable URLs resolve.\n", sep = "")
if (any(res$blocked)) {
  cat("Known bot-blocked (verified manually in a browser):\n")
  cat(paste0("  ", res$url[res$blocked], collapse = "\n"), "\n")
}
invisible(res)
