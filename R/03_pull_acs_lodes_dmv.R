## R/03_pull_acs_lodes_dmv.R -----------------------------------------------
## Census-side pulls.
##
## Phase 2 needs only population (for the R_c denominator). The ACS allocator
## variables are pulled here too because they come from the same endpoint.
## LODES (4d) and DMV (4b) are Phase 3 and are added below when that phase runs.
## -------------------------------------------------------------------------

source(here::here("R", "00_setup.R"))

ACS_YEAR <- "2023"   # latest ACS 5-year available; see docs/data-layouts.md §7
PL_URL   <- "https://api.census.gov/data/2020/dec/pl"
ACS_URL  <- paste0("https://api.census.gov/data/", ACS_YEAR, "/acs/acs5")

## --- population: 2020 decennial PL ---------------------------------------
## Exact counts, fixed vintage. Used as the central P_c / P_k because R_c is a
## ratio of ratios and the 2020 census is the only unmodelled count available
## for both places and counties.

pop_place_pl <- cache_pull(
  "census_pl2020_place_ny.csv", PL_URL,
  function() census_get("2020/dec/pl", list(get = "NAME,P1_001N",
                                            "for" = "place:*", "in" = "state:36"))
) |> mutate(pop_2020 = as.numeric(P1_001N))

pop_county_pl <- cache_pull(
  "census_pl2020_county_ny.csv", PL_URL,
  function() census_get("2020/dec/pl", list(get = "NAME,P1_001N",
                                            "for" = "county:*", "in" = "state:36"))
) |> mutate(pop_2020 = as.numeric(P1_001N))

## --- ACS 5-year: population, households, aggregate household income -------
## B01003_001E population, B11001_001E households, B19025_001E aggregate
## household income. The last two are the §4c delivered-goods allocators.

ACS_VARS <- "NAME,B01003_001E,B11001_001E,B19025_001E"

acs_place <- cache_pull(
  sprintf("census_acs5_%s_place_ny.csv", ACS_YEAR), ACS_URL,
  function() census_get(paste0(ACS_YEAR, "/acs/acs5"),
                        list(get = ACS_VARS, "for" = "place:*", "in" = "state:36"))
)

acs_county <- cache_pull(
  sprintf("census_acs5_%s_county_ny.csv", ACS_YEAR), ACS_URL,
  function() census_get(paste0(ACS_YEAR, "/acs/acs5"),
                        list(get = ACS_VARS, "for" = "county:*", "in" = "state:36"))
)

acs_num <- function(d) {
  d |> mutate(across(starts_with("B"), as.numeric),
              pop_acs = B01003_001E, hh_acs = B11001_001E, agginc_acs = B19025_001E)
}
acs_place  <- acs_num(acs_place)
acs_county <- acs_num(acs_county)

message("03_pull_acs_lodes_dmv.R: ", nrow(pop_place_pl), " places / ",
        nrow(pop_county_pl), " counties (PL 2020); ",
        nrow(acs_place), " places / ", nrow(acs_county), " counties (ACS ", ACS_YEAR, ").")
