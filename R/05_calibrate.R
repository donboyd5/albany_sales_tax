## R/05_calibrate.R --------------------------------------------------------
## Phase 2 (this file, section A): the Route B reduced form -- the observed
##   city share of the county sales tax base, relative to population share, for
##   the New York cities that impose their own sales tax.
## Phase 3 (section B, added when that phase runs): regression of the observed
##   city base on the apportionment prediction, and the resulting error band.
##
## All inputs are cached raw pulls; nothing here touches the network.
## -------------------------------------------------------------------------

source(here::here("R", "00_setup.R"))

## Fiscal years used for the three-year mean. State fiscal year ends 31 March;
## FY2025 = April 2024 - March 2025. The DTF sales tax year (March-February) is
## matched to the fiscal year it mostly overlaps: sales tax year 2024-25 -> FY2025.
ROUTE_B_FYS <- 2023:2025

## --- inputs ---------------------------------------------------------------

## `rate_source = "pub718a_col"` swaps in the rate printed in Publication
## 718-A's percentage column for the six cities where it conflicts with the
## verified rate (see docs/data-layouts.md 3b). Used only as a sensitivity.
read_crosswalk_cities <- function(rate_source = c("verified", "pub718a_col")) {
  rate_source <- match.arg(rate_source)
  cw <- read_csv(file.path(PATHS$crosswalk, "preempt_cities.csv"),
                 col_types = cols(.default = col_character(),
                                  r_k = col_double(), r_c = col_double(),
                                  p_c = col_double(), r_c_pub718a_col = col_double(),
                                  include = col_logical()))
  if (rate_source == "pub718a_col") {
    cw <- cw |> mutate(p_c = ifelse(is.na(p_c), NA, p_c + (r_c_pub718a_col - r_c)),
                       r_c = r_c_pub718a_col)
  }
  cw
}

read_distributions <- function() {
  read_csv(file.path(PATHS$raw, "dtf_distributions.csv"),
           col_types = cols(.default = col_character())) |>
    mutate(fy = as.integer(fiscal_year_ended), amt = as.numeric(amount_distributed))
}

read_county_base <- function() {
  read_csv(file.path(PATHS$raw, "dtf_taxable_sales_by_naics.csv"),
           col_types = cols(.default = col_character())) |>
    mutate(B = as.numeric(taxable_sales),
           ## sales tax year "2024 - 2025" -> FY2025
           fy = as.integer(substr(sales_tax_year, 1, 4)) + 1L)
  ## NOTE: DTF withholds individual county x NAICS cells for disclosure. About
  ## 9.6% of rows have a null taxable_sales. There is no jurisdiction total row,
  ## so a county base is necessarily the sum of its *published* groups and every
  ## sum below uses na.rm = TRUE. suppression_report() quantifies the effect.
}

read_pop <- function() {
  pl_p <- read_csv(file.path(PATHS$raw, "census_pl2020_place_ny.csv"),
                   col_types = cols(.default = col_character())) |>
    transmute(place_fips = paste0("36", place), P_c = as.numeric(P1_001N))
  pl_c <- read_csv(file.path(PATHS$raw, "census_pl2020_county_ny.csv"),
                   col_types = cols(.default = col_character())) |>
    transmute(county_fips = paste0("36", county), P_k = as.numeric(P1_001N))
  list(place = pl_p, county = pl_c)
}

## --- section A: the reduced form -----------------------------------------

## Within county k the county collects r_k outside the preempting cities and
## (r_k - p_i) inside city i, while city i collects r_c on its own base. With
## the collections C observed and the rates verified from Pub 718/718-A:
##
##     B_c = C_c / r_c
##     C_k = r_k * B_k - sum_i p_i * B_i          (identity checked below)
##     R_c = (B_c / B_k) / (P_c / P_k)
##
## B_k is taken directly from ny73-2j3u, which Phase 1 established covers the
## whole county including its preempting cities.
build_route_b <- function(fys = ROUTE_B_FYS, rate_source = "verified") {
  cw   <- read_crosswalk_cities(rate_source)
  dist <- read_distributions()
  base <- read_county_base()
  pop  <- read_pop()

  Bk <- base |>
    group_by(dtf_jurisdiction = jurisdiction, fy) |>
    summarise(B_k = sum(B, na.rm = TRUE), n_sup = sum(is.na(B)), .groups = "drop")

  ## City and county collections, matched by the regex patterns recorded in the
  ## crosswalk. Yonkers deliberately matches two rows (regular + special).
  panel <- cw |>
    filter(include) |>
    tidyr::crossing(fy = fys) |>
    rowwise() |>
    mutate(
      C_c    = sum(dist$amt[dist$fy == fy & grepl(dist_city_pattern,   dist$taxing_jurisdiction)]),
      C_k    = sum(dist$amt[dist$fy == fy & grepl(dist_county_pattern, dist$taxing_jurisdiction)]),
      n_city = sum(dist$fy == fy & grepl(dist_city_pattern, dist$taxing_jurisdiction))
    ) |>
    ungroup() |>
    left_join(Bk,          by = c("dtf_jurisdiction", "fy")) |>
    left_join(pop$place,   by = "place_fips") |>
    left_join(pop$county,  by = "county_fips") |>
    mutate(B_c       = C_c / (r_c / 100),
           s         = B_c / B_k,
           pop_share = P_c / P_k,
           R         = s / pop_share)

  stopifnot(!any(is.na(panel$B_k)), !any(is.na(panel$P_c)), !any(is.na(panel$P_k)),
            all(panel$C_c > 0), all(panel$C_k > 0))
  panel
}

## Three-year mean by city.
summarise_route_b <- function(panel) {
  panel |>
    group_by(city, county, r_k, r_c, p_c) |>
    summarise(B_c = mean(B_c), B_k = mean(B_k), P_c = mean(P_c), P_k = mean(P_k),
              s = mean(s), pop_share = mean(pop_share), R = mean(R),
              n_fy = n(), .groups = "drop") |>
    arrange(desc(R))
}

## Validation 1 for the reduced form:
##   (C_k + sum_i p_i * B_i) / (r_k * B_k)  should be 1,
## where p_i * B_i = C_i * (p_i / r_i). This tests the preemption identity and
## the "county base is the whole county" reading jointly. Where p_i = r_i (every
## city but Yonkers) the term collapses to C_i and the check is insensitive to
## the rate *level* -- it validates the structure, not the individual rates.
check_identity <- function(panel) {
  panel |>
    group_by(county, dtf_jurisdiction, fy, r_k, B_k, C_k) |>
    summarise(C_cities = sum(C_c), preempted = sum(C_c * p_c / r_c), .groups = "drop") |>
    mutate(implied = (C_k + preempted) / (r_k / 100 * B_k)) |>
    group_by(county) |>
    summarise(B_k = mean(B_k), C_k = mean(C_k), C_cities = mean(C_cities),
              preempted = mean(preempted), implied = mean(implied), .groups = "drop") |>
    arrange(implied)
}

## How much of each county's base is unobservable because of cell suppression?
## The count of withheld groups is knowable; their value is not. The check is
## indirect: if suppression were material, the identity check above would fail.
suppression_report <- function(fys = ROUTE_B_FYS) {
  read_county_base() |>
    filter(fy %in% fys) |>
    group_by(jurisdiction, fy) |>
    summarise(n_groups = n(), n_withheld = sum(is.na(B)),
              B_published = sum(B, na.rm = TRUE), .groups = "drop") |>
    group_by(jurisdiction) |>
    summarise(n_groups = mean(n_groups), n_withheld = mean(n_withheld),
              pct_withheld = 100 * mean(n_withheld) / mean(n_groups),
              B_published = mean(B_published), .groups = "drop")
}

## Oswego is excluded from the panel; this reproduces the evidence for that.
oswego_evidence <- function() {
  dist <- read_distributions()
  base <- read_county_base() |> filter(jurisdiction == "OSWEGO") |>
    group_by(fy) |> summarise(B_k = sum(B, na.rm = TRUE), n_sup = sum(is.na(B)), .groups = "drop")
  co   <- dist |> filter(taxing_jurisdiction == "Oswego County Sales and Use Tax") |> select(fy, C_k = amt)
  city <- dist |> filter(taxing_jurisdiction == "City of Oswego Sales and Use Tax") |> select(fy, C_c = amt)
  base |> inner_join(co, by = "fy") |> inner_join(city, by = "fy") |>
    mutate(county_only = C_k / (0.04 * B_k),
           county_plus_city = (C_k + C_c) / (0.04 * B_k)) |>
    arrange(fy)
}

## Albany's break-even R under the status quo. The city currently receives a
## share of Albany County's collections; preempting 1.5 points instead pays off
## when 0.015 * B_c > share * 0.04 * B_k, i.e. when
##     R > (share * 0.04 / 0.015)  ... expressed per unit of population share.
## `share_of_county` is the city's distribution share as a multiple of its
## population share (1.0 = strictly per capita). VERIFY IN PHASE 3.
albany_breakeven <- function(county_rate = 4.0, city_preempt_rate = 1.5,
                             distribution_factor = 0.40) {
  distribution_factor * county_rate / city_preempt_rate
}

if (sys.nframe() == 0L) {   # only when run via Rscript, not when sourced
  route_b_panel <- build_route_b()
  route_b       <- summarise_route_b(route_b_panel)
  saveRDS(route_b_panel, file.path(PATHS$processed, "route_b_panel.rds"))
  saveRDS(route_b,       file.path(PATHS$processed, "route_b_summary.rds"))
  message("05_calibrate.R section A: ", nrow(route_b), " cities, FY",
          min(ROUTE_B_FYS), "-", max(ROUTE_B_FYS), ".")
}


## =========================================================================
## Section B (Phase 3): calibration of the apportionment against the 17
## cities whose base is observed.
## =========================================================================
## Requires R/04_allocate.R. Sourced from the qmd as:
##   source("R/04_allocate.R"); calib <- build_calibration()

## Run the identical apportionment on every calibration city and pair the
## prediction with the observed base from the reduced form.
build_calibration <- function(fys = ANALYSIS_FYS, rate_source = "verified", ...) {
  obs <- summarise_route_b(build_route_b(fys, rate_source))
  cw  <- read_crosswalk_cities() |> filter(include)

  pred <- cw |>
    transmute(city, county,
              ec_name    = paste0(city, " city, New York"),
              place_fips = substr(place_fips, 1, 7),
              county5    = paste0("36", substr(county_fips, 3, 5)),
              dtf_juris  = dtf_jurisdiction,
              dmv_county = dtf_jurisdiction) |>
    rowwise() |>
    mutate(B_c_pred = predicted_base(ec_name, place_fips, county5, dtf_juris,
                                     dmv_county, fys = fys, ...)) |>
    ungroup()

  obs |>
    select(city, county, B_c_obs = B_c, B_k, P_c, P_k, s, pop_share, R) |>
    left_join(pred |> select(city, B_c_pred), by = "city") |>
    mutate(ratio     = B_c_obs / B_c_pred,
           log_obs   = log(B_c_obs),
           log_pred  = log(B_c_pred),
           westchester = county == "Westchester")
}

## Fit log(B_obs) = alpha + beta * log(B_pred), with standard errors clustered
## by county because Fulton, Cattaraugus, Oneida and Westchester each contribute
## more than one city.
fit_calibration <- function(calib, drop_westchester = FALSE) {
  d <- if (drop_westchester) filter(calib, !westchester) else calib
  m <- lm(log_obs ~ log_pred, data = d)
  vc <- sandwich::vcovCL(m, cluster = d$county)
  ct <- lmtest::coeftest(m, vcov. = vc)
  list(model = m, data = d, coeftest = ct, vcov = vc,
       alpha = unname(coef(m)[1]), beta = unname(coef(m)[2]),
       se_alpha = unname(ct[1, 2]), se_beta = unname(ct[2, 2]),
       resid_sd = sd(residuals(m)),
       sigma = summary(m)$sigma,
       r2 = summary(m)$r.squared, n = nrow(d),
       n_clusters = dplyr::n_distinct(d$county))
}

## Apply a fitted calibration to Albany's predicted base and return the central
## estimate with 68% and 90% bands from the residual spread.
apply_calibration <- function(fit, B_pred_albany) {
  ctr <- exp(fit$alpha + fit$beta * log(B_pred_albany))
  s   <- fit$sigma
  tibble(
    B_c_pred_raw = B_pred_albany,
    B_c_central  = ctr,
    lo68 = ctr * exp(-s),           hi68 = ctr * exp(s),
    lo90 = ctr * exp(-1.645 * s),   hi90 = ctr * exp(1.645 * s),
    resid_sd_logs = s)
}

## Revenue = 0.005 * B_c * (1 - phi) * beta
revenue_from_base <- function(B_c, phi = 0, beta = 1, rate = 0.005) {
  rate * B_c * (1 - phi) * beta
}

## phi, observed as 1 - (county distributions / (0.04 * county taxable sales)).
albany_phi <- function(fys = ANALYSIS_FYS) {
  b <- read_county_base() |> filter(jurisdiction == "ALBANY", fy %in% fys) |>
    group_by(fy) |> summarise(B = sum(B, na.rm = TRUE), .groups = "drop")
  d <- read_distributions() |>
    filter(taxing_jurisdiction == "Albany County Sales and Use Tax") |> select(fy, C = amt)
  inner_join(b, d, by = "fy") |> mutate(phi = 1 - C / (0.04 * B))
}

## Calibration under an alternative modelling choice: re-run the apportionment
## variant on every calibration city AND on Albany, refit, and apply. This is
## the consistent way to test an allocator -- the sensitivity rows that apply
## the central fit to a variant prediction understate the effect of a choice
## that also changes the calibration cities' predictions.
build_calibration_variant <- function(..., fys = ANALYSIS_FYS, rate_source = "verified") {
  obs <- summarise_route_b(build_route_b(fys, rate_source))
  cw  <- read_crosswalk_cities(rate_source) |> filter(include)
  pred <- cw |>
    transmute(city, county,
              ec_name = paste0(city, " city, New York"), place_fips = substr(place_fips, 1, 7),
              county5 = paste0("36", substr(county_fips, 3, 5)),
              dtf_juris = dtf_jurisdiction, dmv_county = dtf_jurisdiction) |>
    rowwise() |>
    mutate(B_c_pred = apportion_variant(ec_name, place_fips, county5, dtf_juris, dmv_county,
                                        fys = fys, ...)) |>
    ungroup()
  obs |> select(city, county, B_c_obs = B_c, B_k, P_c, P_k, s, pop_share, R) |>
    left_join(pred |> select(city, B_c_pred), by = "city") |>
    mutate(ratio = B_c_obs / B_c_pred, log_obs = log(B_c_obs), log_pred = log(B_c_pred),
           westchester = county == "Westchester")
}


## =========================================================================
## Section C: diagnostics -- why observed and predicted differ
## =========================================================================

## Cities excluded from the preferred calibration. Both have a verified
## structural reason, established from sources independent of this analysis,
## that does not apply to Albany. Excluding observations after seeing that they
## are inconvenient is illegitimate; excluding them for a documented reason
## that is known not to transfer is not. Both fits are always reported.
CALIB_EXCLUDE <- c(
  Salamanca  = "100% of the city's population is on the Seneca Nation's Allegany Territory (2020 Census Block Assignment Files, AIANNH area 0080). Retail there is substantially outside the state and local tax base under the 1842 Buffalo Creek Treaty and 20 NYCRR 529.9, while the Economic Census counts its receipts.",
  Ogdensburg = "The city tax was re-imposed effective 1 March 2022 (DTF notice ST-22-1), so its jurisdiction code is new and its implied base share is still rising (3.01% -> 3.38% -> 3.45% of the county base over FY2023-25, against a flat ~47% for long-established Ithaca). Cross-border traffic from Canada also fell sharply over the same period. Albany would face the same new-code effect in its first years, so this is used for the first-year discount rather than for the steady state."
)

## Share of the variance in log(observed/predicted) that is between counties
## rather than between cities within a county.
county_effect_share <- function(calib) {
  summary(lm(log(ratio) ~ county, data = calib))$r.squared
}

## Per-city decomposition: how much of the predicted base comes from each
## sourcing class, and what allocator level was reached.
calibration_diagnostics <- function(fys = ANALYSIS_FYS) {
  cw  <- read_crosswalk_cities() |> filter(include)
  cal <- build_calibration(fys)
  purrr::map_dfr(seq_len(nrow(cw)), function(i) {
    nm <- paste0(cw$city[i], " city, New York"); pf <- substr(cw$place_fips[i], 1, 7)
    c5 <- paste0("36", substr(cw$county_fips[i], 3, 5)); dj <- cw$dtf_jurisdiction[i]
    d  <- apportion_city(nm, pf, c5, dj, dj, fys = fys)
    st <- d |> filter(sourcing_class %in% c("store", "delivered_split"))
    tibble(city = cw$city[i],
           store_share_of_pred = sum(st$B_cg, na.rm = TRUE) / sum(d$B_cg, na.rm = TRUE),
           wt_sector_fallback  = sum(st$B_kg[grepl("sector", st$store_method)]) / sum(st$B_kg),
           a_store = sum(st$B_cg, na.rm = TRUE) / sum(st$B_kg))
  }) |> left_join(cal |> select(city, county, ratio, pop_share, R), by = "city")
}

## County base per capita -- the "how much activity is not tied to residents"
## measure that motivates, but does not statistically explain, the county effect.
county_base_per_capita <- function(fys = ANALYSIS_FYS) {
  pop <- read_pop()$county
  read_county_base() |> filter(fy %in% fys) |>
    group_by(jurisdiction, fy) |> summarise(B = sum(B, na.rm = TRUE), .groups = "drop") |>
    group_by(jurisdiction) |> summarise(B = mean(B), .groups = "drop")
}
