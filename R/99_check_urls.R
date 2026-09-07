## R/99_check_urls.R -------------------------------------------------------
## Verify that every URL cited in the analysis documents and the crosswalk
## files still resolves. Run before publishing.
## Note: legal aggregators (doi.org, findlaw, justia, nysenate) return 403 to
## non-browser clients; statutes are cited by section, not by URL.
## -------------------------------------------------------------------------
source(here::here("R", "00_setup.R"))

urls <- c(
  list.files(here("analysis"), "\\.qmd$", full.names = TRUE),
  list.files(here("data", "crosswalk"), "\\.csv$", full.names = TRUE)
) |>
  map(readLines, warn = FALSE) |> unlist() |>
  stringr::str_extract_all("https?://[^\\s<>\")]+") |> unlist() |>
  stringr::str_remove("[.,;]$") |> unique() |> sort()

check <- function(u) {
  r <- try(request(u) |>
             req_user_agent(paste("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
                                  "(KHTML, like Gecko) Chrome/120.0 Safari/537.36")) |>
             req_method("HEAD") |> req_timeout(30) |>
             req_error(is_error = \(x) FALSE) |> req_perform(), silent = TRUE)
  if (inherits(r, "try-error")) NA_integer_ else resp_status(r)
}

res <- tibble(url = urls) |> mutate(status = map_int(url, check))
bad <- res |> filter(is.na(status) | status >= 400)
print(as.data.frame(res), right = FALSE)
if (nrow(bad)) {
  cat("\n*** ", nrow(bad), " URL(s) did not return 2xx/3xx:\n", sep = "")
  print(as.data.frame(bad))
} else cat("\nAll ", nrow(res), " URLs resolve.\n", sep = "")
invisible(res)
