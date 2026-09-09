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
##                    Dealers, plus 9261 Administration of Economic Programs.
##                    Tax Law s.1214 sources sales of vehicles required to be
##                    registered to the purchaser's residence (Pub 838). 9261
##                    is the NAICS group of motor-vehicle departments; its
##                    $8.5B of statewide "taxable sales" is spread across
##                    counties in proportion to population and car ownership
##                    (Albany County's share equals its population share), which
##                    is the signature of tax collected by DMV at registration
##                    on private-party vehicle sales -- residence-sourced -- not
##                    of state agencies selling taxable goods in Albany.
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
##                    agriculture, mining and public administration. These are
##                    the taxable sales of business-serving vendors (and their
##                    use tax), sourced to where the customer is, so the
##                    allocator is where private economic activity is.
##                    Government purchases are EXEMPT (Tax Law s.1116(a)(1)),
##                    so public-administration jobs are excluded from the
##                    central allocator; total employment is a sensitivity.
naics_class <- function(g) {
  s2 <- substr(g, 1, 2); s3 <- substr(g, 1, 3)
  dplyr::case_when(
    s2 == "22" | s3 == "517"                    ~ "utilities",
    g %in% c("4411", "4412", "9261")            ~ "motor_vehicle",
    g %in% c("4441", "4442", "4491", "4492")    ~ "delivered_split",
    s3 %in% c("441","444","445","449","455",
              "456","457","458","459")          ~ "store",
    s2 %in% c("71", "72")                       ~ "store",
    s3 %in% c("811", "812", "532")              ~ "store",
    TRUE                                        ~ "business"
  )
}

CLASS_RATIONALE <- c(
  utilities = "NAICS 22 and 517. The Albany City School District's 3% tax covers both utilities and telecommunications (TSB-M-90(6)S), giving a directly measured city base; allocated by the business allocator (private workplace employment) in the generic apportionment so the same method runs for every calibration city, with the measured value as a check.",
  motor_vehicle = "Sales of vehicles required to be registered are sourced to the purchaser's residence, not the dealer's location (Tax Law s.1214; Publication 838), so dealer location carries no information. Allocated by resident registrations. NAICS 9261 is included because its statewide taxable sales ($8.5B) are distributed across counties like population and car ownership, consistent with tax collected by DMV at registration on private-party vehicle sales rather than with state-agency vendor activity.",
  delivered_split = "Predominantly delivered goods. Establishment receipts overstate the selling jurisdiction because delivery is destination-sourced, so the group is split 50/50 between the store allocator and the residence allocator.",
  store = "Over-the-counter sales sourced where the sale occurs, so establishment receipts are the natural allocator and origin is approximately destination.",
  business = "Taxable sales of business-serving vendors (wholesale, contractors, information, professional and administrative services, etc.) and purchases subject to use tax, sourced to the customer's location. Allocated by where private economic activity is: workplace employment excluding public administration, since government purchases are exempt under Tax Law s.1116(a)(1). Total employment and Economic Census payroll are sensitivities."
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
           source         = CLASS_SOURCE[sourcing_class],
           customer_type  = ifelse(sourcing_class == "business",
                                   business_customer_type(naics_industry_group), NA),
           customer_rationale = ifelse(sourcing_class == "business",
                                   CUSTOMER_RATIONALE[business_customer_family(naics_industry_group)], NA),
           customer_source = ifelse(sourcing_class == "business", CUSTOMER_SOURCE, NA))
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
STORE_ALLOCATORS <- c("receipts", "payroll", "establishments")
store_var_order <- function(store_allocator) {
  switch(store_allocator, receipts = c("RCPTOT", "PAYANN"), payroll = c("PAYANN", "RCPTOT"),
         establishments = c("ESTAB", "PAYANN"))
}
store_share_for_group <- function(g, ec_place, ec_county, place_name, county_fips3,
                                  vars = c("RCPTOT", "PAYANN")) {
  keys <- c(g, substr(g, 1, 3), EC_SECTOR(substr(g, 1, 2)))
  lvls <- c("4-digit", "3-digit", "sector")
  for (v in vars) {
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

## Alternative motor-vehicle allocator: ACS aggregate vehicles available, a
## stock measure with exact place geography (no ZIP splitting).
acs_vehicle_share <- function(place_fips5, county_fips3) {
  p <- acs_vehicles$vehicles[acs_vehicles$level == "place"  & acs_vehicles$geo == place_fips5]
  k <- acs_vehicles$vehicles[acs_vehicles$level == "county" & acs_vehicles$geo == county_fips3]
  if (length(p) != 1 || length(k) != 1 || is.na(k) || k == 0) return(NA_real_)
  p / k
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
BUSINESS_ALLOCATORS <- c("lodes_ex_pubadmin", "lodes", "ec_payroll", "lodes_ex_exempt",
                         "ec_estab", "residence", "assessed")

apportion_city <- function(ec_place_name, place_fips, county_fips5, dtf_juris,
                           dmv_county, fys = ANALYSIS_FYS,
                           delivered_to_residence = 0.5,
                           resid_var = "agginc",
                           business_allocator = BUSINESS_ALLOCATORS,
                           store_allocator = STORE_ALLOCATORS) {
  business_allocator <- match.arg(business_allocator)
  store_allocator <- match.arg(store_allocator)
  county_fips3 <- substr(county_fips5, 3, 5)
  place_fips5  <- substr(place_fips, 3, 7)
  cw <- read_naics_crosswalk()

  base <- read_county_base() |>
    filter(jurisdiction == dtf_juris, fy %in% fys) |>
    group_by(naics_industry_group) |>
    summarise(B_kg = mean(B, na.rm = TRUE), .groups = "drop") |>
    filter(!is.na(B_kg)) |>
    left_join(cw, by = "naics_industry_group")

  a_work  <- switch(business_allocator,
    lodes_ex_pubadmin = work_share_ex_pubadmin(place_fips, county_fips5),
    lodes_ex_exempt   = work_share_ex_exempt(place_fips, county_fips5),
    lodes             = work_share(place_fips, county_fips5),
    ec_payroll        = ec_payroll_share(ec_place_name, county_fips3),
    ec_estab          = ec_estab_share(ec_place_name, county_fips3),
    residence         = resid_share(place_fips5, county_fips3, resid_var),
    assessed          = assessed_share(ec_place_name, county_fips5))
  a_resid <- resid_share(place_fips5, county_fips3, resid_var)
  a_mv    <- mv_share(place_fips, dmv_county)

  ## store shares, group by group
  st <- map(base$naics_industry_group, store_share_for_group,
            ec_place = ec_place_sector, ec_county = ec_county_sector,
            place_name = ec_place_name, county_fips3 = county_fips3,
            vars = store_var_order(store_allocator))
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
        sourcing_class %in% c("utilities", "business") ~ c(
          lodes_ex_pubadmin = "LODES employment excl. public admin",
          lodes = "LODES total employment",
          ec_payroll = "EC payroll",
          lodes_ex_exempt = "LODES employment excl. govt, education, health",
          ec_estab = "EC establishments",
          residence = "ACS household income (residence)",
          assessed = "Taxable commercial and industrial full market value (assessment rolls)")[business_allocator],
        sourcing_class == "motor_vehicle"              ~ "DMV resident registrations",
        sourcing_class == "delivered_split"            ~ paste0("50% ", store_method,
                                                                " / 50% ACS ", resid_var),
        TRUE                                           ~ store_method),
      fallback = !grepl("^EC (RCPTOT|PAYANN|ESTAB) 4-digit", store_method) &
                 sourcing_class %in% c("store", "delivered_split"),
      B_cg = B_kg * a_g)
}

## Total predicted city base. NA if any class's sharing rule is unavailable
## for this city (e.g. the assessed-value rule in Westchester), so that the
## city drops out of that variant's calibration instead of losing a class.
predicted_base <- function(...) {
  d <- apportion_city(...)
  if (any(is.na(d$a_g) & d$B_kg > 0)) return(NA_real_)
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

## Bound on the exempt-institution problem: employment excluding public
## administration AND the education and health-care sectors (CNS15, CNS16),
## which are dominated by exempt universities and hospitals but also contain
## taxable private clinics and schools. A bound, not an estimate.
work_share_ex_exempt <- function(place_fips, county_fips5) {
  d <- lodes_place |> filter(cty == county_fips5) |>
    mutate(priv = C000 - CNS20 - CNS15 - CNS16)
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
                              business_allocator = BUSINESS_ALLOCATORS,
                              ecommerce_frac = 0,
                              mv_include_4413 = FALSE,
                              mv_allocator = c("dmv", "acs_vehicles"),
                              business_by_customer = FALSE,
                              store_allocator = STORE_ALLOCATORS) {
  business_allocator <- match.arg(business_allocator)
  mv_allocator <- match.arg(mv_allocator)
  store_allocator <- match.arg(store_allocator)
  d <- apportion_city(ec_place_name, place_fips, county_fips5, dtf_juris, dmv_county,
                      fys = fys, delivered_to_residence = delivered_to_residence,
                      resid_var = resid_var, business_allocator = business_allocator,
                      store_allocator = store_allocator)
  county_fips3 <- substr(county_fips5, 3, 5)
  place_fips5  <- substr(place_fips, 3, 7)
  a_resid <- resid_share(place_fips5, county_fips3, resid_var)
  a_mv    <- mv_share(place_fips, dmv_county)

  if (mv_allocator == "acs_vehicles") {
    a_mv <- acs_vehicle_share(place_fips5, county_fips3)
    d <- d |> mutate(a_g = ifelse(sourcing_class == "motor_vehicle", a_mv, a_g))
  }
  if (mv_include_4413) {
    d <- d |> mutate(a_g = ifelse(naics_industry_group == "4413", a_mv, a_g))
  }
  if (ecommerce_frac > 0) {
    d <- d |> mutate(a_g = ifelse(naics_industry_group %in% ECOMMERCE_PRONE,
                                  (1 - ecommerce_frac) * a_g + ecommerce_frac * a_resid, a_g))
  }
  if (business_by_customer) {
    ## groups whose customers are mostly households follow residence; mixed
    ## groups are split evenly; mostly-business groups keep the employment share
    d <- d |> mutate(ct = ifelse(sourcing_class == "business",
                                 business_customer_type(naics_industry_group), NA),
                     a_g = case_when(ct == "household" ~ a_resid,
                                     ct == "mixed"     ~ 0.5 * a_g + 0.5 * a_resid,
                                     TRUE              ~ a_g))
  }
  if (any(is.na(d$a_g) & d$B_kg > 0)) return(NA_real_)
  sum(d$B_kg * d$a_g, na.rm = TRUE)
}


## =========================================================================
## 6. Inside the business class: who is the customer?
## =========================================================================
## The DTF table classifies taxable sales by the VENDOR's industry. The
## "business" class is every vendor industry that is not a store, a vehicle
## dealer, a utility or a delivered-goods retailer -- it is a residual, and its
## customers are not all businesses. This section tags each group by who its
## taxable customers mostly are, so that the chapter on apportionment can show
## the composition and so that a variant can allocate the household-facing part
## by residence instead of by employment. The tags are a reading of the NAICS
## definitions together with what New York actually taxes (Publication 750;
## sales for resale exempt; capital improvements exempt but repair and
## maintenance taxable; residential energy exempt in Albany County per
## Publication 718-R). They are judgments and are presented as such.

## 3-digit "family" used for the rationale text and the chapter's tables.
business_customer_family <- function(g) {
  s2 <- substr(g, 1, 2); s3 <- substr(g, 1, 3)
  dplyr::case_when(
    s2 == "42"                               ~ "wholesale",
    g == "3341"                              ~ "mfg_computers",
    g %in% c("3121", "3399", "3118", "3115") ~ "mfg_consumer",
    s2 %in% c("31", "32", "33")              ~ "mfg_other",
    g == "2361"                              ~ "constr_residential",
    s3 == "238"                              ~ "constr_specialty",
    s2 == "23"                               ~ "constr_other",
    g == "5415" | g == "5182" | g == "5199"  ~ "it_business",
    g %in% c("5132", "5192", "5131", "5122") ~ "info_mixed",
    g %in% c("5121", "5161", "5162")         ~ "info_consumer",
    s2 == "51"                               ~ "info_mixed",
    s2 == "52"                               ~ "finance",
    g == "5311"                              ~ "real_estate_lessors",
    s2 == "53"                               ~ "real_estate_other",
    g %in% c("5414", "5419")                 ~ "prof_mixed",
    s2 == "54"                               ~ "prof_business",
    s2 == "55"                               ~ "management",
    g %in% c("5616", "5617", "5621", "5622", "5629") ~ "admin_mixed",
    g == "5615"                              ~ "admin_consumer",
    s2 == "56"                               ~ "admin_business",
    s2 %in% c("61", "62")                    ~ "edu_health",
    s2 == "81"                               ~ "orgs_households",
    g %in% c("4853", "4859", "4871", "4872", "4879", "4884", "4885") ~ "transport_consumer",
    s2 %in% c("48", "49")                    ~ "transport_business",
    s2 == "11"                               ~ "agriculture",
    s2 == "21"                               ~ "mining",
    s2 == "92"                               ~ "government",
    TRUE                                     ~ "unclassified"
  )
}

CUSTOMER_TYPE_OF_FAMILY <- c(
  wholesale = "business", mfg_computers = "mixed", mfg_consumer = "mixed", mfg_other = "business",
  constr_residential = "household", constr_specialty = "mixed", constr_other = "business",
  it_business = "business", info_mixed = "mixed", info_consumer = "household",
  finance = "mixed", real_estate_lessors = "mixed", real_estate_other = "business",
  prof_mixed = "mixed", prof_business = "business", management = "business",
  admin_mixed = "mixed", admin_consumer = "household", admin_business = "business",
  edu_health = "household", orgs_households = "household",
  transport_consumer = "household", transport_business = "business",
  agriculture = "mixed", mining = "business", government = "household", unclassified = "mixed")

business_customer_type <- function(g) unname(CUSTOMER_TYPE_OF_FAMILY[business_customer_family(g)])

CUSTOMER_FAMILY_LABEL <- c(
  wholesale = "Wholesale trade (42)",
  mfg_computers = "Computer and peripheral manufacturing (3341)",
  mfg_consumer = "Consumer-facing manufacturing (beverages, bakeries, miscellaneous goods)",
  mfg_other = "Other manufacturing (31-33)",
  constr_residential = "Residential building construction (2361)",
  constr_specialty = "Specialty trade contractors (238)",
  constr_other = "Nonresidential and heavy construction (2362, 237)",
  it_business = "IT services, data processing and hosting (5415, 5182, 5199)",
  info_mixed = "Software and other publishers, web portals (5131, 5132, 5192, other 51)",
  info_consumer = "Movies, broadcasting and streaming (5121, 516)",
  finance = "Finance and insurance (52)",
  real_estate_lessors = "Lessors of real estate, incl. self-storage (5311)",
  real_estate_other = "Real estate agents and managers (5312, 5313)",
  prof_mixed = "Design and other professional services, incl. veterinary and photography (5414, 5419)",
  prof_business = "Legal, accounting, engineering, IT consulting, advertising, other professional (54)",
  management = "Management of companies (55)",
  admin_mixed = "Building services, security, waste (5616, 5617, 562)",
  admin_consumer = "Travel arrangement (5615)",
  admin_business = "Office, facilities, employment and business support services (561)",
  edu_health = "Education and health care (61, 62)",
  orgs_households = "Membership organizations, private households (813, 814)",
  transport_consumer = "Passenger transport, sightseeing, towing (485, 487, 4884)",
  transport_business = "Freight, rail, air, couriers, warehousing (48-49)",
  agriculture = "Agriculture (11)",
  mining = "Mining and quarrying (21)",
  government = "Government other than 9261 (92)",
  unclassified = "Unclassified (99)")

CUSTOMER_RATIONALE <- c(
  wholesale = "Sales for resale are exempt, so a wholesaler's taxable sales go to end users: contractors, offices, restaurants, institutions and fleets. Residential heating oil (4247) is exempt in Albany County (Pub 718-R), so that group's taxable sales are commercial too.",
  mfg_computers = "Computer makers sell direct to businesses and, through online stores, to households.",
  mfg_consumer = "Breweries, bakeries and makers of miscellaneous goods sell at the factory door and online to households as well as to businesses.",
  mfg_other = "Manufacturers' direct taxable sales are of equipment, materials and printed matter to other businesses; sales to resellers are exempt.",
  constr_residential = "Home builders' taxable sales are repair and remodeling work for homeowners (capital improvements are exempt).",
  constr_specialty = "Electrical, plumbing, heating and finishing contractors do taxable repair and maintenance work for homeowners and for commercial buildings alike.",
  constr_other = "Nonresidential builders and heavy contractors serve businesses and governments; whatever is taxable is commercial.",
  it_business = "Custom programming, systems integration, hosting and data processing are sold almost entirely to organizations.",
  info_mixed = "Prewritten software, books, directories and portal services are sold to businesses and to households.",
  info_consumer = "Theatre admissions, subscription programming and streaming are household purchases.",
  finance = "Banks and finance companies have little taxable activity; what there is (equipment leases, safe deposit boxes, repossessed vehicles) is mixed.",
  real_estate_lessors = "Lessors' taxable receipts are largely self-storage and parking, used by households and businesses.",
  real_estate_other = "Property managers and agents buy and sell services on behalf of owners; commercial.",
  prof_mixed = "Interior design, photography, veterinary boarding and grooming serve households; the rest of the family serves businesses.",
  prof_business = "Legal, accounting, engineering, consulting and advertising firms' taxable sales (signs, promotional goods, taxable information services) go to businesses.",
  management = "Corporate headquarters transact with their own affiliates.",
  admin_mixed = "Cleaning, landscaping, pest control, alarm monitoring and trash collection are bought by homeowners and by commercial buildings.",
  admin_consumer = "Travel agents and room remarketers sell to travellers.",
  admin_business = "Staffing, facilities support, document and call-centre services are sold to organizations.",
  edu_health = "Tuition and medical care are exempt; the taxable remainder (bookstores, cafeterias, optical goods, gift shops) is bought by students, patients and visitors.",
  orgs_households = "Membership organizations' taxable sales (bar and restaurant receipts, merchandise) go to members and the public.",
  transport_consumer = "Limousine, sightseeing and towing services are taxable and mostly bought by individuals.",
  transport_business = "Freight, rail, air cargo, courier and warehousing customers are shippers, i.e. businesses.",
  agriculture = "Nurseries and farm stands sell to households; farm services to farms.",
  mining = "Sand, gravel and stone go to contractors.",
  government = "Government units' own taxable sales (park fees, municipal parking and golf) are bought by the public.",
  unclassified = "Vendors with no NAICS code on file.")

CUSTOMER_SOURCE <- "https://www.census.gov/naics/ ; https://www.tax.ny.gov/pdf/publications/sales/pub750.pdf ; https://www.tax.ny.gov/forms/publications/st/pub718r.htm"

## Economic Census establishment counts, matched sectors, as a business
## allocator: the city's share of the county's business *locations* rather than
## of its jobs. A location buys supplies, services and equipment whether it has
## five employees or five thousand, so this weights small businesses more and
## hospitals and headquarters less than employment does.
ec_estab_share <- function(ec_place_name, county_fips3) {
  is_sector <- function(x) grepl("^[0-9]{2}$|^[0-9]{2}-[0-9]{2}$", x)
  p <- ec_place_sector |>
    filter(NAME == ec_place_name, is_sector(NAICS2022), !is.na(ESTAB)) |>
    select(NAICS2022, p = ESTAB)
  k <- ec_county_sector |>
    filter(county == county_fips3, is_sector(NAICS2022), !is.na(ESTAB)) |>
    select(NAICS2022, k = ESTAB)
  j <- inner_join(p, k, by = "NAICS2022")
  if (nrow(j) == 0 || sum(j$k) == 0) return(NA_real_)
  sum(j$p) / sum(j$k)
}


## =========================================================================
## 7. Assessed-value business allocator
## =========================================================================
## The city's share of the county's TAXABLE commercial and industrial property
## at full market value (ORPTS assessment rolls, roll section 1, property
## classes 400-499 and 700-799). Exempt property -- state offices, colleges,
## hospitals, schools, churches -- is in roll section 8 and drops out
## automatically, which is exactly the weakness of the jobs rule. Westchester
## municipalities do not carry a usable full market value in the dataset, so
## the four Westchester cities return NA and are left out of that variant's
## calibration.
roll_county_name <- function(county_fips5) {
  nm <- read_csv(file.path(PATHS$raw, "census_pl2020_county_ny.csv"), col_types = cols(.default = "c")) |>
    transmute(fips5 = paste0(state, county), name = sub(" County, New York", "", NAME))
  x <- nm$name[nm$fips5 == county_fips5]
  if (length(x) != 1) return(NA_character_)
  sub("^St\\. ", "St ", x)
}
assessed_share <- function(ec_place_name, county_fips5) {
  city <- sub(" city, New York$", "", ec_place_name)
  cty  <- roll_county_name(county_fips5)
  if (is.na(cty) || cty == "Westchester") return(NA_real_)
  d <- roll_by_class |> filter(county_name == cty, roll_section == 1,
                               (property_class >= 400 & property_class < 500) | (property_class >= 700 & property_class < 800))
  if (nrow(d) == 0 || sum(d$fmv) == 0) return(NA_real_)
  ## some cities appear as "Rome, Inside" / "Rome, Outside" (inside and outside
  ## a former district); both belong to the city
  p <- d |> filter(is_city, sub(", (Inside|Outside)$", "", municipality_name) == city)
  if (nrow(p) == 0) return(NA_real_)
  sum(p$fmv) / sum(d$fmv)
}
