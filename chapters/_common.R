## Shared setup for every chapter. Loads the results computed by
## R/06_results.R and defines the formatting helpers. No computation of
## substance happens here, so every chapter shows the same numbers.
suppressPackageStartupMessages({
  library(here); library(dplyr); library(tidyr); library(knitr); library(ggplot2)
})
RES_PATH <- here("data", "processed", "results.rds")
if (!file.exists(RES_PATH)) stop("Run `Rscript R/06_results.R` first: ", RES_PATH, " is missing.")
R <- readRDS(RES_PATH)
options(knitr.kable.NA = "")

fm <- function(x, d = 1) formatC(x / 1e6, format = "f", digits = d, big.mark = ",")   # $ millions
fb <- function(x, d = 2) formatC(x / 1e9, format = "f", digits = d)                    # $ billions
fp <- function(x, d = 1) paste0(formatC(100 * x, format = "f", digits = d), "%")       # percent
f3 <- function(x) formatC(x, format = "f", digits = 3)
f2 <- function(x) formatC(x, format = "f", digits = 2)
fn <- function(x) formatC(x, format = "d", big.mark = ",")
sd_up <- function(sg) paste0("+", formatC(100 * (exp(sg) - 1), format = "f", digits = 0), "%")
sd_dn <- function(sg) paste0("-", formatC(100 * (1 - exp(-sg)), format = "f", digits = 0), "%")
rev <- function(b, beta = 1, ph = R$phi) 0.005 * b * (1 - ph) * beta

## short-hands used in prose
REV <- R$REV; REV_all <- R$REV_all; B_k <- R$B_k; B_pred <- R$B_pred
est <- R$est; est_pref <- R$est_pref; fit <- R$fit; fit_pref <- R$fit_pref
pop <- R$pop; P_c <- R$P_c; P_k <- R$P_k; phi <- R$phi; s_cal <- R$s_cal; R_cal <- R$R_cal
appo <- R$appo; calib <- R$calib; route_b <- R$route_b
kb <- function(d, ...) kable(d, format = "pipe", ...)
