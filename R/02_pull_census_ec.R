## R/02_pull_census_ec.R ---------------------------------------------------
## 2022 Economic Census (`ecnbasic`) -- the store-based allocator (§4a).
##
## Phase 2 needs only the retail sector figures used in the Route B narrative.
## Phase 3 adds the finer NAICS levels and the CBP/ZIP fallback.
##
## IMPORTANT (docs/data-layouts.md §5): `economic place` codes are 8 digits -- a
## 3-digit prefix plus the 5-digit place FIPS. Albany city is 00101000, NOT
## 01000; querying with the bare place FIPS returns HTTP 204 and an empty body.
## Codes must be discovered from a `for=economic place:*` listing.
## -------------------------------------------------------------------------

source(here::here("R", "00_setup.R"))

EC_URL  <- "https://api.census.gov/data/2022/ecnbasic.html"
EC_PATH <- "2022/ecnbasic"
EC_VARS <- "NAICS2022,NAICS2022_LABEL,NAME,GEO_ID,ESTAB,RCPTOT,EMP,PAYANN"

## Sector-level (2-digit) receipts for every New York economic place and every
## New York county. Used for the county-vs-places coverage check and for the
## retail comparison in analysis/route-b.qmd.
ec_place_sector <- cache_pull(
  "ec2022_place_sector_ny.csv", EC_URL,
  function() {
    census_get(EC_PATH, list(get = EC_VARS,
                             "for" = "economic place:*", "in" = "state:36"))
  })

ec_county_sector <- cache_pull(
  "ec2022_county_sector_ny.csv", EC_URL,
  function() {
    census_get(EC_PATH, list(get = EC_VARS,
                             "for" = "county:*", "in" = "state:36"))
  })

## RCPTOT, PAYANN are $1,000; ESTAB, EMP are counts. Withheld cells come back
## as NA or as a value with a companion flag; both are treated as missing here
## and the fallback used for each group is recorded downstream in Phase 3.
ec_num <- function(d) {
  d |> mutate(across(c(ESTAB, RCPTOT, EMP, PAYANN), ~suppressWarnings(as.numeric(.x))))
}
ec_place_sector  <- ec_num(ec_place_sector)
ec_county_sector <- ec_num(ec_county_sector)

## Places that lie in Albany County. The `economic place` prefix is not a county
## code, so membership is resolved by name against the county's municipalities.
ALBANY_CO_PLACES <- c("Albany city", "Cohoes city", "Watervliet city",
                      "Colonie village", "Colonie town (balance)",
                      "Guilderland town", "Bethlehem town", "Menands village",
                      "Green Island village", "Voorheesville village",
                      "Altamont village", "Ravena village",
                      "Coeymans town", "New Scotland town", "Berne town",
                      "Knox town", "Rensselaerville town", "Westerlo town")

ec_albany_places <- function(naics = "44-45") {
  ec_place_sector |>
    filter(NAICS2022 == naics,
           sub(", New York$", "", NAME) %in% ALBANY_CO_PLACES)
}

ec_albany_county <- function(naics = "44-45") {
  ec_county_sector |>
    filter(NAICS2022 == naics, county == "001")
}

message("02_pull_census_ec.R: ", nrow(ec_place_sector), " place-sector rows, ",
        nrow(ec_county_sector), " county-sector rows.")
