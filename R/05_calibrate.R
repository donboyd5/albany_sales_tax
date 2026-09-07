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

read_crosswalk_cities <- function() {
  read_csv(file.path(PATHS$crosswalk, "preempt_cities.csv"),
           col_types = cols(.default = col_character(),
                            r_k = col_double(), r_c = col_double(),
                            p_c = col_double(), include = col_logical()))
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
build_route_b <- function(fys = ROUTE_B_FYS) {
  cw   <- read_crosswalk_cities()
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

## Validation 1 for the reduced form: with p_i = r_i the rates cancel, so
##   (C_k + sum_i C_i) / (r_k * B_k)  should be 1.
## This tests the preemption identity and the "county base is the whole county"
## reading jointly, and is insensitive to the individual city rates.
check_identity <- function(panel) {
  panel |>
    group_by(county, dtf_jurisdiction, fy, r_k, B_k, C_k) |>
    summarise(C_cities = sum(C_c), .groups = "drop") |>
    mutate(implied = (C_k + C_cities) / (r_k / 100 * B_k)) |>
    group_by(county) |>
    summarise(B_k = mean(B_k), C_k = mean(C_k), C_cities = mean(C_cities),
              implied = mean(implied), .groups = "drop") |>
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
