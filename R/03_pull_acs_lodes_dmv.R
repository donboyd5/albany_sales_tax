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

## ACS aggregate vehicles available (B25046_001E): a residence-based vehicle
## measure with exact place geography and no ZIP splitting, used to check the
## DMV allocator. It is a stock of all vehicles rather than a flow of recent
## purchases.
acs_vehicles <- cache_pull(
  sprintf("census_acs5_%s_vehicles_ny.csv", ACS_YEAR), ACS_URL,
  function() {
    bind_rows(
      census_get(paste0(ACS_YEAR, "/acs/acs5"),
                 list(get = "NAME,B25046_001E", "for" = "place:*", "in" = "state:36")) |>
        mutate(level = "place", geo = place),
      census_get(paste0(ACS_YEAR, "/acs/acs5"),
                 list(get = "NAME,B25046_001E", "for" = "county:*", "in" = "state:36")) |>
        mutate(level = "county", geo = county)) |>
      select(level, geo, NAME, B25046_001E)
  }) |> mutate(vehicles = as.numeric(B25046_001E))

## --- LEHD LODES WAC (§4d business-purchase allocator) ---------------------
## Workplace employment by block, aggregated to place through the LODES
## crosswalk's `stplc` field. lehdr 1.2.0 cannot aggregate to place (agg_geo
## accepts only block/bg/tract/county/state), so the join is done by hand.
## LODES8 latest vintage is 2023.

LODES_YEAR <- 2023L
LODES_WAC_URL <- sprintf(
  "https://lehd.ces.census.gov/data/lodes/LODES8/ny/wac/ny_wac_S000_JT00_%d.csv.gz", LODES_YEAR)
LODES_XWALK_URL <- "https://lehd.ces.census.gov/data/lodes/LODES8/ny/ny_xwalk.csv.gz"

## C000 = total jobs. CNS* are the NAICS-sector job counts, kept so the
## business allocator can be checked sector by sector. Public administration
## (CNS20) is retained in numerator and denominator per the project plan and is
## reported separately because state government is a large taxable purchaser
## concentrated in the city and absent from the Economic Census.
lodes_place <- cache_pull(
  sprintf("lodes_wac_%d_ny_by_place.csv", LODES_YEAR), LODES_WAC_URL,
  function() {
    tmp_w <- tempfile(fileext = ".csv.gz"); tmp_x <- tempfile(fileext = ".csv.gz")
    utils::download.file(LODES_WAC_URL,   tmp_w, mode = "wb", quiet = TRUE)
    utils::download.file(LODES_XWALK_URL, tmp_x, mode = "wb", quiet = TRUE)
    wac <- read_csv(tmp_w, col_types = cols(.default = col_double(),
                                            w_geocode = col_character()))
    xw  <- read_csv(tmp_x, col_types = cols(.default = col_character())) |>
      select(tabblk2020, cty, stplc)
    unlink(c(tmp_w, tmp_x))
    wac |>
      left_join(xw, by = c("w_geocode" = "tabblk2020")) |>
      group_by(cty, stplc) |>
      summarise(across(c(C000, paste0("CNS", sprintf("%02d", 1:20))),
                       \(x) sum(x, na.rm = TRUE)),
                n_blocks = n(), .groups = "drop")
  }) |>
  mutate(across(c(C000, paste0("CNS", sprintf("%02d", 1:20)), n_blocks), as.numeric))

## --- ZCTA to place relationship file (2020) -------------------------------
## Albany's ZIPs straddle Colonie, Guilderland and Menands, so ZIP-based
## allocators must be split across places by the overlap, never assigned whole.
ZCTA_PLACE_URL <- paste0("https://www2.census.gov/geo/docs/maps-data/data/",
                         "rel2020/zcta520/tab20_zcta520_place20_natl.txt")

zcta_place <- cache_pull(
  "zcta_place_rel2020.csv", ZCTA_PLACE_URL,
  function() {
    read_delim(ZCTA_PLACE_URL, delim = "|", col_types = cols(.default = col_character()),
               progress = FALSE) |>
      filter(substr(GEOID_PLACE_20, 1, 2) == "36" | substr(GEOID_ZCTA5_20, 1, 3) %in%
               c("120", "121", "122", "123", "124", "125", "126", "127", "128",
                 "129", "130", "131", "132", "133", "134", "135", "136", "137",
                 "138", "139", "140", "141", "142", "143", "144", "145", "146",
                 "147", "148", "149"))
  })

## --- DMV registrations (§4b motor vehicle allocator) ----------------------
## Aggregated on the server. `county` is UPPER CASE; `city` is the postal city
## and must not be used as a municipality. Restricted to VEH and to recent
## model years as a purchase-flow proxy.

DMV_URL <- "https://data.ny.gov/Transportation/Vehicle-Snowmobile-and-Boat-Registrations/w4pv-hbkt"
DMV_MIN_MODEL_YEAR <- 2024L   # ~2 model years of flow

dmv_by_zip <- cache_pull(
  sprintf("dmv_veh_my%d_plus_by_county_zip.csv", DMV_MIN_MODEL_YEAR), DMV_URL,
  function() {
    counties <- read_csv(file.path(PATHS$crosswalk, "preempt_cities.csv"),
                         col_types = cols(.default = col_character()))$dtf_jurisdiction |>
      unique() |> c("ALBANY") |> unique()
    socrata_get("w4pv-hbkt", list(
      select = "county, zip, state, count(*) as n",
      where  = sprintf('record_type = "VEH" and model_year >= %d and county in (%s)',
                       DMV_MIN_MODEL_YEAR,
                       paste0('"', counties, '"', collapse = ",")),
      group  = "county, zip, state",
      order  = "county, zip",
      limit  = 100000L))
  }) |>
  mutate(n = as.numeric(n))

message("03: LODES ", nrow(lodes_place), " county-place cells; ",
        "ZCTA-place ", nrow(zcta_place), " rows; DMV ", nrow(dmv_by_zip), " county-zip cells.")

## --- exact ZIP -> place population weights --------------------------------
## The ZCTA-to-place relationship file carries land area only, and weighting by
## area badly understates a dense central city inside a split ZCTA (ZCTA 12203
## is 40% of Albany city by area but far more than that by population). Exact
## population weights are built instead from three block-level sources:
##   1. 2020 Census block populations (decennial PL, P1_001N)
##   2. block -> place, from the 2020 Census Block Assignment Files
##   3. block -> ZCTA, from the 2020 ZCTA-to-block relationship file
## The relationship file is ~1 GB nationally and is stream-filtered to the 13
## counties in the analysis rather than downloaded whole.

ANALYSIS_COUNTIES <- c("001","009","011","017","035","053","065","075",
                       "089","091","109","113","119")

BAF_URL  <- "https://www2.census.gov/geo/docs/maps-data/data/baf2020/BlockAssign_ST36_NY.zip"
ZCTABLK_URL <- paste0("https://www2.census.gov/geo/docs/maps-data/data/rel2020/",
                      "zcta520/tab20_zcta520_tabblock20_natl.txt")

block_pop <- cache_pull(
  "census_pl2020_block_13counties.csv", PL_URL,
  function() {
    map_dfr(ANALYSIS_COUNTIES, function(cty) {
      census_get("2020/dec/pl", list(get = "P1_001N", "for" = "block:*",
                                     "in" = paste0("state:36 county:", cty)))
    })
  }) |>
  transmute(block = paste0(state, county, tract, block), pop = as.numeric(P1_001N))

block_place <- cache_pull(
  "census_baf2020_block_place_ny.csv", BAF_URL,
  function() {
    tmp <- tempfile(fileext = ".zip"); td <- tempfile(); dir.create(td)
    utils::download.file(BAF_URL, tmp, mode = "wb", quiet = TRUE)
    f <- utils::unzip(tmp, files = "BlockAssign_ST36_NY_INCPLACE_CDP.txt", exdir = td)
    out <- read_delim(f, delim = "|", col_types = cols(.default = col_character()),
                      progress = FALSE) |>
      filter(substr(BLOCKID, 3, 5) %in% ANALYSIS_COUNTIES) |>
      transmute(block = BLOCKID, place_fips = ifelse(is.na(PLACEFP), NA_character_,
                                                     paste0("36", PLACEFP)))
    unlink(c(tmp, td), recursive = TRUE)
    out
  })

## Stream-filter the national ZCTA-to-block file; only fields 2 (ZCTA) and
## 10 (block) are kept, for the 13 analysis counties.
block_zcta <- cache_pull(
  "census_zcta_block_rel2020_13counties.csv", ZCTABLK_URL,
  function() {
    pat <- paste0("^(", paste0("36", ANALYSIS_COUNTIES, collapse = "|"), ")")
    con <- url(ZCTABLK_URL, open = "r")
    on.exit(close(con), add = TRUE)
    keep <- list(); i <- 0L
    repeat {
      ln <- readLines(con, n = 200000L, warn = FALSE)
      if (length(ln) == 0) break
      f <- strsplit(ln, "|", fixed = TRUE)
      blk <- vapply(f, function(x) if (length(x) >= 10) x[10] else "", "")
      zc  <- vapply(f, function(x) if (length(x) >= 2)  x[2]  else "", "")
      sel <- grepl(pat, blk) & nzchar(zc)
      if (any(sel)) { i <- i + 1L; keep[[i]] <- tibble(zcta = zc[sel], block = blk[sel]) }
    }
    bind_rows(keep)
  })

## ZCTA x place population weights: for each ZCTA, the share of its population
## that falls inside each place. Blocks not in any place get place_fips NA.
zip_place_weights <- block_zcta |>
  left_join(block_pop,   by = "block") |>
  left_join(block_place, by = "block") |>
  mutate(pop = ifelse(is.na(pop), 0, pop)) |>
  group_by(zcta, place_fips) |>
  summarise(pop = sum(pop), .groups = "drop") |>
  group_by(zcta) |>
  mutate(w = ifelse(sum(pop) > 0, pop / sum(pop), 0)) |>
  ungroup()

message("03: block_pop ", nrow(block_pop), "; block_place ", nrow(block_place),
        "; block_zcta ", nrow(block_zcta), "; zip-place weights ", nrow(zip_place_weights))


## --- County Business Patterns, ZIP level: establishments in retail and food
## service, 2021-2023, for a post-Economic-Census drift check on the city's
## store share. CBP has no place geography, so ZIPs are split to the city with
## the same block-population weights as the DMV allocator. Employment is
## suppressed at ZIP level for these sectors; establishment counts are not.
CBP_YEARS <- 2021:2023
cbp_zip_estab <- cache_pull(
  "cbp_zip_estab_retail_food_2021_2023.csv", "https://api.census.gov/data/2023/cbp",
  function() {
    purrr::map_dfr(CBP_YEARS, function(y) purrr::map_dfr(c("44-45", "72"), function(n) {
      census_get(sprintf("%d/cbp", y), list(get = "ESTAB", "for" = "zip code:*", NAICS2017 = n)) |>
        mutate(year = y)
    })) |>
      rename(zip = `zip code`) |>
      filter(substr(zip, 1, 3) %in% c("120", "121", "122", "123"))
  }) |>
  mutate(ESTAB = as.numeric(ESTAB), year = as.integer(year))


## --- Assessment rolls (ORPTS, Open NY 7vem-aaz7), 2025, summarized on the
## server by county x municipality x roll section x property class for Albany
## County and the calibration counties. Full market value is ORPTS's
## equalized figure; county_taxable_value is the taxable assessment. Roll
## section 1 is ordinary taxable property, 3 state-owned land, 8 wholly
## exempt. Never downloaded whole (4.7 million parcels).
ROLL_URL <- "https://data.ny.gov/Government-Finance/Property-Assessment-Data-from-Local-Assessment-Rol/7vem-aaz7"
ROLL_YEAR <- 2025L
ROLL_COUNTIES <- c("Albany", "Cattaraugus", "Cayuga", "Chenango", "Fulton", "Madison", "Oneida",
                   "St Lawrence", "Saratoga", "Tompkins", "Warren", "Westchester")
roll_by_class <- cache_pull(
  sprintf("orpts_roll_%d_by_muni_class.csv", ROLL_YEAR), ROLL_URL,
  function() {
    socrata_get("7vem-aaz7", list(
      select = paste("roll_year, county_name, municipality_name, municipality_code, roll_section,",
                     "property_class, property_class_description,",
                     "sum(full_market_value) as fmv, sum(county_taxable_value) as ctv,",
                     "sum(assessment_total) as av, count(*) as n"),
      where  = sprintf("roll_year=%d and county_name in (%s)", ROLL_YEAR,
                       paste0('"', ROLL_COUNTIES, '"', collapse = ",")),
      group  = paste("roll_year, county_name, municipality_name, municipality_code, roll_section,",
                     "property_class, property_class_description"),
      order  = "county_name, municipality_code, roll_section, property_class",
      limit  = 200000L))
  }) |>
  mutate(across(c(fmv, ctv, av, n), as.numeric), roll_section = as.integer(roll_section),
         property_class = as.integer(property_class),
         ## ORPTS municipality codes: the third and fourth digits are below 20 for cities
         is_city = as.integer(substr(municipality_code, 3, 4)) < 20)
