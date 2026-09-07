## R/01_pull_dtf.R ---------------------------------------------------------
## DTF pulls: taxable sales and purchases (ny73-2j3u) and state/local sales
## tax distributions (5g2s-tnb7), plus the AS001 certification index.
##
## Everything here is an aggregated SoQL query (CLAUDE.md rule 3) cached under
## data/raw/ with a MANIFEST row.
## -------------------------------------------------------------------------

source(here::here("R", "00_setup.R"))

DTF_SALES_ID <- "ny73-2j3u"
DTF_DIST_ID  <- "5g2s-tnb7"
DTF_SALES_URL <- "https://data.ny.gov/Government-Finance/Taxable-Sales-And-Purchases-Quarterly-Data-Beginni/ny73-2j3u/about_data"
DTF_DIST_URL  <- "https://data.ny.gov/Government-Finance/State-and-Local-Sales-Tax-Distributions-Beginning-/5g2s-tnb7"

## --- 1. taxable sales by jurisdiction x year x NAICS group ----------------

## Every jurisdiction, every NAICS group, sales tax years 2022-23 onward (the
## NAICS 2022 era -- see docs/data-layouts.md for why the series is split at
## that point). Aggregated over quarters.
dtf_sales <- cache_pull(
  "dtf_taxable_sales_by_naics.csv", DTF_SALES_URL,
  function() {
    socrata_get(DTF_SALES_ID, list(
      select = paste("jurisdiction, sales_tax_year, naics_industry_group, description,",
                     "sum(taxable_sales_and_purchases) as taxable_sales,",
                     "count(*) as n_quarters"),
      where  = 'sales_tax_year >= "2022 - 2023"',
      group  = "jurisdiction, sales_tax_year, naics_industry_group, description",
      order  = "jurisdiction, sales_tax_year, naics_industry_group",
      limit  = 200000L))
  }) |>
  mutate(taxable_sales = as.numeric(taxable_sales),
         n_quarters    = as.integer(n_quarters))

## Quarter-level status (F final / P preliminary) so the qmd can label years.
dtf_status <- cache_pull(
  "dtf_sales_status_by_year.csv", DTF_SALES_URL,
  function() {
    socrata_get(DTF_SALES_ID, list(
      select = "sales_tax_year, sales_tax_quarter, selling_period, status, count(*) as n",
      where  = 'jurisdiction = "ALBANY" and sales_tax_year >= "2022 - 2023"',
      group  = "sales_tax_year, sales_tax_quarter, selling_period, status",
      order  = "sales_tax_year, sales_tax_quarter"))
  })

## --- 2. distributions by taxing jurisdiction x fiscal year ----------------

dtf_dist <- cache_pull(
  "dtf_distributions.csv", DTF_DIST_URL,
  function() {
    socrata_get(DTF_DIST_ID, list(
      select = "fiscal_year_ended, taxing_jurisdiction, jurisdiction_code, amount_distributed",
      where  = "fiscal_year_ended >= 2014",
      order  = "fiscal_year_ended, jurisdiction_code",
      limit  = 5000L))
  }) |>
  mutate(fiscal_year_ended  = as.integer(fiscal_year_ended),
         jurisdiction_code  = as.integer(jurisdiction_code),
         amount_distributed = as.numeric(amount_distributed))

## --- 3. AS001 certification index ----------------------------------------

## Only the link list is cached here. The .xlsx files themselves are pulled on
## demand in Phase 3 for the recent-month reconciliation; they are large and
## git-ignored.
AS001_URL <- "https://www.tax.ny.gov/research/stats/statistics/sales_tax/government/as001.htm"

as001_index <- cache_pull(
  "dtf_as001_index.csv", AS001_URL,
  function() {
    pg <- rvest::read_html(AS001_URL)
    tibble(
      text = rvest::html_text2(rvest::html_elements(pg, "a")),
      href = rvest::html_attr(rvest::html_elements(pg, "a"), "href")
    ) |>
      filter(!is.na(href), grepl("\\.xlsx?$", href, ignore.case = TRUE)) |>
      mutate(url = ifelse(grepl("^http", href), href,
                          paste0("https://www.tax.ny.gov", href))) |>
      select(text, url) |>
      distinct()
  })

message("01_pull_dtf.R: ",
        nrow(dtf_sales), " sales rows, ",
        nrow(dtf_dist), " distribution rows, ",
        nrow(as001_index), " AS001 links.")
