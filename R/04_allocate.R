## R/04_allocate.R ---------------------------------------------------------
## Phase 3. Maps every NAICS group in the DTF county table to exactly one
## sourcing class, computes the city share a_g for each class, and assembles
## the city base B_c = sum_g B_k,g * a_g.
##
## Everything here is written to work for ANY (place, county) pair, because
## R/05_calibrate.R runs the identical apportionment on the 17 preempting
## cities to calibrate it.
## -------------------------------------------------------------------------

source(here::here("R", "00_setup.R"))
source(here::here("R", "02_pull_census_ec.R"))
source(here::here("R", "03_pull_acs_lodes_dmv.R"))
source(here::here("R", "05_calibrate.R"))   # readers for the DTF files

ANALYSIS_FYS <- 2023:2025

## =========================================================================
## 1. Sourcing classes
## =========================================================================

## Class assignment for a 4-digit NAICS 2022 group.
##
##   utilities        NAICS 22 and 517. Measured for Albany from the school
##                    district tax; allocated by workplace employment in the
##                    generic apportionment so the calibration can run
##                    everywhere.
##   motor_vehicle    4411 Automobile Dealers and 4412 Other Motor Vehicle
##                    Dealers. Tax Law s.1214 sources sales of vehicles
##                    required to be registered to the purchaser's residence.
##                    4413 (parts, accessories, tires) is ordinary
##                    over-the-counter retail and stays store-based; it is
##                    small ($65M of a $9.1B base) and is tested in the
##                    sensitivity table.
##   delivered_split  4441, 4442, 4491, 4492 -- building materials, lawn and
##                    garden, furniture and home furnishings, electronics and
##                    appliances. Substantially delivered, so split 50/50
##                    between the store allocator and the residence allocator.
##   store            The rest of retail, plus accommodation (721), food
##                    services (722), arts/entertainment/recreation (71),
##                    repair (811), personal services (812) and rental (532).
##   business         Everything else: wholesale, manufacturing, construction,
##                    information other than telecom, finance, real estate
##                    other than rental, professional, administrative,
##                    education, health, other services, transportation,
##                    agriculture, mining and public administration.
naics_class <- function(g) {
  s2 <- substr(g, 1, 2); s3 <- substr(g, 1, 3)
  dplyr::case_when(
    s2 == "22" | s3 == "517"                    ~ "utilities",
    g %in% c("4411", "4412")                    ~ "motor_vehicle",
    g %in% c("4441", "4442", "4491", "4492")    ~ "delivered_split",
    s3 %in% c("441","444","445","449","455",
              "456","457","458","459")          ~ "store",
    s2 %in% c("71", "72")                       ~ "store",
    s3 %in% c("811", "812", "532")              ~ "store",
    TRUE                                        ~ "business"
  )
}

CLASS_RATIONALE <- c(
  utilities = "NAICS 22 and 517. The Albany City School District's 3% tax covers both utilities and telecommunications (TSB-M-90(6)S), giving a directly measured city base; allocated by workplace employment in the generic apportionment so the same method runs for every calibration city.",
  motor_vehicle = "Sales of vehicles required to be registered are sourced to the purchaser's residence, not the dealer's location (Tax Law s.1214), so dealer location carries no information. Allocated by resident registrations.",
  delivered_split = "Predominantly delivered goods. Establishment receipts overstate the selling jurisdiction because delivery is destination-sourced, so the group is split 50/50 between the store allocator and the residence allocator.",
  store = "Over-the-counter sales sourced where the sale occurs, so establishment receipts are the natural allocator and origin is approximately destination.",
  business = "Purchases by businesses and governments, and purchases subject to use tax. Consumed where the establishment operates, so workplace employment is the allocator. State government is a large taxable purchaser concentrated in the city and is absent from the Economic Census, so public administration is retained in both numerator and denominator."
)

CLASS_SOURCE <- c(
  utilities = "https://tax.ny.gov/pdf/memos/sales/m90_6s.pdf",
  motor_vehicle = "https://www.tax.ny.gov/pdf/publications/sales/pub718.pdf",
  delivered_split = "https://api.census.gov/data/2022/ecnbasic.html",
  store = "https://api.census.gov/data/2022/ecnbasic.html",
  business = "https://lehd.ces.census.gov/data/"
)

## Build (and cache) the crosswalk file from the groups actually present in the
## DTF table, so it can never drift out of sync with the data.
build_naics_crosswalk <- function(path = file.path(PATHS$crosswalk, "naics_sourcing_class.csv")) {
  groups <- read_county_base() |>
    filter(fy %in% ANALYSIS_FYS) |>
    distinct(naics_industry_group, description) |>
    arrange(naics_industry_group)
  out <- groups |>
    mutate(sourcing_class = naics_class(naics_industry_group),
           rationale      = CLASS_RATIONALE[sourcing_class],
           source         = CLASS_SOURCE[sourcing_class])
  write_csv(out, path)
  out
}

read_naics_crosswalk <- function(path = file.path(PATHS$crosswalk, "naics_sourcing_class.csv")) {
  if (!file.exists(path)) build_naics_crosswalk(path)
  read_csv(path, col_types = cols(.default = col_character()))
}

## =========================================================================
## 2. The store allocator: Economic Census, finest unsuppressed NAICS level
## =========================================================================

## EC publishes 2-digit sectors as ranges ("44-45", "31-33", "48-49").
EC_SECTOR <- function(s2) {
  dplyr::case_when(
    s2 %in% c("44", "45") ~ "44-45",
    s2 %in% c("31", "32", "33") ~ "31-33",
    s2 %in% c("48", "49") ~ "48-49",
    TRUE ~ s2)
}

## City and county receipts for one NAICS key, from the cached EC pulls.
ec_lookup <- function(ec_place, ec_county, place_name, county_fips3, key, var) {
  p <- ec_place[[var]][ec_place$NAME == place_name & ec_place$NAICS2022 == key]
  k <- ec_county[[var]][ec_county$county == county_fips3 & ec_county$NAICS2022 == key]
  if (length(p) != 1 || length(k) != 1) return(c(NA_real_, NA_real_))
  c(p, k)
}

## Share of county receipts held by the place, for a 4-digit DTF group, taking
## the finest NAICS level at which BOTH the place and the county publish an
## unsuppressed value. Falls back RCPTOT -> PAYANN and 4-digit -> 3 -> sector.
## Returns the share and the method actually used.
store_share_for_group <- function(g, ec_place, ec_county, place_name, county_fips3) {
  keys <- c(g, substr(g, 1, 3), EC_SECTOR(substr(g, 1, 2)))
  lvls <- c("4-digit", "3-digit", "sector")
  for (v in c("RCPTOT", "PAYANN")) {
    for (i in seq_along(keys)) {
      pk <- ec_lookup(ec_place, ec_county, place_name, county_fips3, keys[i], v)
      if (!any(is.na(pk)) && pk[2] > 0) {
        return(list(a = pk[1] / pk[2], method = paste0("EC ", v, " ", lvls[i])))
      }
    }
  }
  list(a = NA_real_, method = "unresolved")
}

## =========================================================================
## 3. Class-level allocators
## =========================================================================

## Workplace employment share (LODES WAC 2023), used for `business` and for
## `utilities` in the generic apportionment.
work_share <- function(place_fips, county_fips5) {
  d <- lodes_place |> filter(cty == county_fips5)
  if (nrow(d) == 0 || sum(d$C000) == 0) return(NA_real_)
  sum(d$C000[d$stplc == place_fips]) / sum(d$C000)
}

## Public administration share, reported separately as a diagnostic.
pubadmin_share <- function(place_fips, county_fips5) {
  d <- lodes_place |> filter(cty == county_fips5)
  if (nrow(d) == 0 || sum(d$CNS20) == 0) return(NA_real_)
  sum(d$CNS20[d$stplc == place_fips]) / sum(d$CNS20)
}

## Residence allocator: ACS aggregate household income share (central) or
## household share (sensitivity).
resid_share <- function(place_fips5, county_fips3, var = c("agginc", "hh")) {
  var <- match.arg(var)
  col <- if (var == "agginc") "B19025_001E" else "B11001_001E"
  p <- as.numeric(acs_place[[col]][acs_place$place == place_fips5])
  k <- as.numeric(acs_county[[col]][acs_county$county == county_fips3])
  if (length(p) != 1 || length(k) != 1 || is.na(k) || k == 0) return(NA_real_)
  p / k
}

## Motor-vehicle allocator: resident registrations, model year >= cutoff,
## assigned from ZIP to place with the block-population weights. Registrations
## carrying an out-of-state ZIP are leasing and fleet registrants with no
## in-county residence to assign; they are dropped from both numerator and
## denominator, which distributes them in proportion to the resident pattern.
mv_share <- function(place_fips, dmv_county) {
  d <- dmv_by_zip |> filter(county == dmv_county, state == "NY")
  if (nrow(d) == 0 || sum(d$n) == 0) return(NA_real_)
  w <- zip_place_weights |> filter(place_fips == !!place_fips) |> select(zcta, w)
  d <- d |> left_join(w, by = c("zip" = "zcta")) |> mutate(w = ifelse(is.na(w), 0, w))
  sum(d$n * d$w) / sum(d$n)
}

## Directly measured utility share, Albany only: ACSD collections / 0.03 over
## county NAICS 22 + 517 taxable sales.
albany_measured_utility_share <- function(fys = ANALYSIS_FYS) {
  d <- read_distributions()
  acsd <- mean(d$amt[d$fy %in% fys &
                     d$taxing_jurisdiction == "Albany City School District Consumer Utilities"])
  b <- read_county_base() |>
    filter(jurisdiction == "ALBANY", fy %in% fys,
           substr(naics_industry_group, 1, 2) == "22" |
           substr(naics_industry_group, 1, 3) == "517") |>
    group_by(fy) |> summarise(B = sum(B, na.rm = TRUE), .groups = "drop")
  (acsd / 0.03) / mean(b$B)
}

## =========================================================================
## 4. Apportionment for one city
## =========================================================================

## Returns one row per NAICS group with the county base, the class, the
## allocator used, a_g, the implied city base and the fallback flag.
##
##   ec_place_name  e.g. "Albany city, New York"
##   place_fips     7-digit, e.g. "3601000"
##   county_fips5   e.g. "36001"
##   dtf_juris      e.g. "ALBANY"
##   dmv_county     e.g. "ALBANY"
apportion_city <- function(ec_place_name, place_fips, county_fips5, dtf_juris,
                           dmv_county, fys = ANALYSIS_FYS,
                           delivered_to_residence = 0.5,
                           resid_var = "agginc") {

  county_fips3 <- substr(county_fips5, 3, 5)
  place_fips5  <- substr(place_fips, 3, 7)
  cw <- read_naics_crosswalk()

  base <- read_county_base() |>
    filter(jurisdiction == dtf_juris, fy %in% fys) |>
    group_by(naics_industry_group) |>
    summarise(B_kg = mean(B, na.rm = TRUE), .groups = "drop") |>
    filter(!is.na(B_kg)) |>
    left_join(cw, by = "naics_industry_group")

  a_work  <- work_share(place_fips, county_fips5)
  a_resid <- resid_share(place_fips5, county_fips3, resid_var)
  a_mv    <- mv_share(place_fips, dmv_county)

  ## store shares, group by group
  st <- map(base$naics_industry_group, store_share_for_group,
            ec_place = ec_place_sector, ec_county = ec_county_sector,
            place_name = ec_place_name, county_fips3 = county_fips3)
  base$a_store  <- map_dbl(st, "a")
  base$store_method <- map_chr(st, "method")

  ## a store group whose EC cell is unresolved falls back to the base-weighted
  ## store share for that city
  store_default <- with(base[base$sourcing_class %in% c("store", "delivered_split") &
                              !is.na(base$a_store), ],
                        sum(a_store * B_kg) / sum(B_kg))
  base <- base |>
    mutate(a_store_used = ifelse(is.na(a_store), store_default, a_store),
           store_method = ifelse(is.na(a_store), "city store default", store_method))

  base |>
    mutate(
      a_g = case_when(
        sourcing_class == "utilities"       ~ a_work,
        sourcing_class == "business"        ~ a_work,
        sourcing_class == "motor_vehicle"   ~ a_mv,
        sourcing_class == "delivered_split" ~ (1 - delivered_to_residence) * a_store_used +
                                               delivered_to_residence * a_resid,
        TRUE                                ~ a_store_used),
      allocator = case_when(
        sourcing_class %in% c("utilities", "business") ~ "LODES workplace employment",
        sourcing_class == "motor_vehicle"              ~ "DMV resident registrations",
        sourcing_class == "delivered_split"            ~ paste0("50% ", store_method,
                                                                " / 50% ACS ", resid_var),
        TRUE                                           ~ store_method),
      fallback = !grepl("^EC (RCPTOT|PAYANN) 4-digit", store_method) &
                 sourcing_class %in% c("store", "delivered_split"),
      B_cg = B_kg * a_g)
}

## Total predicted city base.
predicted_base <- function(...) {
  d <- apportion_city(...)
  sum(d$B_cg, na.rm = TRUE)
}

message("04_allocate.R loaded.")

## =========================================================================
## 5. Sensitivity variants
## =========================================================================

## Alternative business allocator: workplace employment excluding public
## administration. This is the direct test of how much the estimate depends on
## state government, which is concentrated in the city and is the single
## weakest-measured part of the base.
work_share_ex_pubadmin <- function(place_fips, county_fips5) {
  d <- lodes_place |> filter(cty == county_fips5) |> mutate(priv = C000 - CNS20)
  if (nrow(d) == 0 || sum(d$priv) <= 0) return(NA_real_)
  sum(d$priv[d$stplc == place_fips]) / sum(d$priv)
}

## Alternative business allocator: Economic Census annual payroll. `ecnbasic`
## publishes no all-sector ("00") row, so the share is summed over the 2-digit
## sectors present and unsuppressed for BOTH the place and the county, which
## keeps numerator and denominator on the same footing. Note this omits public
## administration entirely -- the Economic Census does not cover it -- which is
## exactly why it is a sensitivity and not the central allocator.
ec_payroll_share <- function(ec_place_name, county_fips3) {
  is_sector <- function(x) grepl("^[0-9]{2}$|^[0-9]{2}-[0-9]{2}$", x)
  p <- ec_place_sector |>
    filter(NAME == ec_place_name, is_sector(NAICS2022), !is.na(PAYANN)) |>
    select(NAICS2022, p = PAYANN)
  k <- ec_county_sector |>
    filter(county == county_fips3, is_sector(NAICS2022), !is.na(PAYANN)) |>
    select(NAICS2022, k = PAYANN)
  j <- inner_join(p, k, by = "NAICS2022")
  if (nrow(j) == 0 || sum(j$k) == 0) return(NA_real_)
  sum(j$p) / sum(j$k)
}

## Groups where e-commerce plausibly hides after NAICS 2022 eliminated sector
## 454. There is no published split, so this is a class-assignment sensitivity,
## not an estimate: `frac` of these groups is moved to the residence allocator.
ECOMMERCE_PRONE <- c("4551", "4552", "4599", "4581", "4591", "4592")

## Re-run the apportionment with one knob changed. Returns the total city base.
apportion_variant <- function(ec_place_name, place_fips, county_fips5, dtf_juris,
                              dmv_county, fys = ANALYSIS_FYS,
                              delivered_to_residence = 0.5,
                              resid_var = "agginc",
                              business_allocator = c("lodes", "lodes_ex_pubadmin", "ec_payroll"),
                              ecommerce_frac = 0,
                              mv_include_4413 = FALSE) {
  business_allocator <- match.arg(business_allocator)
  d <- apportion_city(ec_place_name, place_fips, county_fips5, dtf_juris, dmv_county,
                      fys = fys, delivered_to_residence = delivered_to_residence,
                      resid_var = resid_var)
  county_fips3 <- substr(county_fips5, 3, 5)
  place_fips5  <- substr(place_fips, 3, 7)

  a_bus <- switch(business_allocator,
    lodes             = work_share(place_fips, county_fips5),
    lodes_ex_pubadmin = work_share_ex_pubadmin(place_fips, county_fips5),
    ec_payroll        = ec_payroll_share(ec_place_name, county_fips3))
  a_resid <- resid_share(place_fips5, county_fips3, resid_var)
  a_mv    <- mv_share(place_fips, dmv_county)

  d <- d |>
    mutate(a_g = ifelse(sourcing_class %in% c("business", "utilities"), a_bus, a_g))

  if (mv_include_4413) {
    d <- d |> mutate(a_g = ifelse(naics_industry_group == "4413", a_mv, a_g))
  }
  if (ecommerce_frac > 0) {
    d <- d |> mutate(a_g = ifelse(naics_industry_group %in% ECOMMERCE_PRONE,
                                  (1 - ecommerce_frac) * a_g + ecommerce_frac * a_resid, a_g))
  }
  sum(d$B_kg * d$a_g, na.rm = TRUE)
}
