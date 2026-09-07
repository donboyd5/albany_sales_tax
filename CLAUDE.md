# CLAUDE.md — Albany City 0.5% add-on sales tax revenue estimate

## Project purpose

Estimate, reproducibly and with an explicit error band, the annual revenue the
City of Albany, NY would collect from a hypothetical 0.5 percentage-point add-on
sales and use tax imposed on the same base that Albany County taxes at 4%,
destination-sourced, layered on top of the existing 8% combined rate (4% state +
4% county) with **no preemption** of the county tax and **no change** to county
distributions to its municipalities. The central difficulty is that the City of
Albany's taxable sales base is not published by anyone; it is estimated here by
NAICS-group apportionment of the observed *county* base, and that apportionment
method is then calibrated against the 18 New York cities outside NYC that impose
their own sales tax and whose city base therefore *is* observable from published
distributions.

## Identity being estimated

    Revenue = 0.005 x B_c x (1 - phi) x beta

- `B_c`  City of Albany taxable sales and purchases (same base the county taxes at 4%).
- `phi`  administrative deduction, observed as `1 - (county net distributions / (0.04 x county taxable sales))`. Expect a small number; report it.
- `beta` behavioral factor for the 0.5-point intra-county rate differential.
         Default 1.0; sensitivity 0.97-1.0 with the source stated.

## Script roles

| script | role |
|---|---|
| `R/00_setup.R`          | libraries, paths, Census-key guard, helpers: `socrata_get()`, `census_get()`, `cache_pull()`, MANIFEST maintenance |
| `R/01_pull_dtf.R`       | DTF Socrata pulls: taxable sales `ny73-2j3u`, distributions `5g2s-tnb7`; AS001 xlsx links |
| `R/02_pull_census_ec.R` | 2022 Economic Census `ecnbasic` (RCPTOT/ESTAB/EMP/PAYANN) for economic places + counties; CBP/ZBP fallback |
| `R/03_pull_acs_lodes_dmv.R` | ACS B19025/B11001, decennial PL population, LODES WAC + crosswalk, DMV registrations (aggregated) |
| `R/04_allocate.R`       | NAICS -> sourcing class mapping, allocator shares `a_g`, assemble `B_c` |
| `R/05_calibrate.R`      | 18-city observed vs predicted base, log-log fit, residual SD, band |

## Standing rules (do not relax without asking)

1. **Provenance.** Every number that appears in a rendered document must trace to
   a cached raw file under `data/raw/` and a script under `R/`. No hand-entered
   figures anywhere except the crosswalk tables in `data/crosswalk/`, and those
   must carry a `source` column containing a URL.
2. **Verify schema first.** Before using any dataset, pull its metadata or column
   list, write it to `docs/data-layouts.md`, and cache the sample. Schema
   assumptions written in the project prompt or in this file are to be verified,
   never trusted.
3. **Socrata aggregation.** Pull aggregated queries (SoQL `$select ... $group ...`)
   rather than full downloads. The DMV registrations file (`w4pv-hbkt`) is
   millions of rows and must never be downloaded whole.
4. **No fabrication.** Do not invent data, URLs, citations, or field names. If a
   source is unreachable or a field does not exist, stop and report it. Never
   substitute a plausible-looking value for a missing one.
5. **Secrets.** The Census key is read from `.Renviron` as `CENSUS_API_KEY` and is
   never written to any file, log, cached pull, or chat message. `R/00_setup.R`
   checks `nzchar(Sys.getenv("CENSUS_API_KEY"))` at startup and stops with
   instructions if it is empty.
6. **R only**, dependencies managed with `renv`. Use `censusapi` for Economic
   Census / ACS / decennial pulls; use `httr2` directly for Socrata.
7. **Caching.** Raw pulls are written once and reused; re-pull only on explicit
   request. Every raw file gets a row in `data/raw/MANIFEST.csv`
   (`file, source_url, pulled_at, sha256`).

## Phase gates

Work proceeds in phases; **stop and report** at the end of Phase 0 and Phase 1
before continuing, because the schema checks in Phase 1 may change the plan.
Commit at the end of each phase.

- **Phase 0** Bootstrap: scaffolding, renv, git init. Report tree, `renv::status()`, key presence.
- **Phase 1** Data access and schema checks. Report source x reachable x key fields x issues. **STOP.**
- **Phase 2** Route B benchmark: `R_c = (B_c/B_k)/(P_c/P_k)` for the 18 preempting cities -> `analysis/route-b.qmd`.
- **Phase 3** Apportionment, calibration, revenue estimate -> `analysis/city-halfpct-revenue.qmd`.

## Sourcing classes (Phase 3)

Every NAICS group in the DTF county table maps to exactly one class, recorded in
`data/crosswalk/naics_sourcing_class.csv` with a `rationale` column:

- **4a store-based** — allocator: 2022 EC `RCPTOT` at `economic place`, finest
  unsuppressed NAICS level; fall back to `PAYANN`, then ZBP payroll; record the
  fallback per group.
- **4b motor vehicles (441)** — sourced to purchaser residence; allocator: DMV
  registrations aggregated by ZIP/county, ZIP->place via the 2020 ZCTA-Place
  relationship file. Never assign whole ZIPs; Albany ZIPs straddle Colonie,
  Guilderland and Menands.
- **4c delivered-to-residence** — nonstore/e-commerce plus the delivered half of
  furniture/appliance/building-material groups; allocator: ACS B19025 aggregate
  household income share (central), B11001 household share (sensitivity).
- **4d business purchases and use tax** — allocator: LODES WAC 2022 workplace
  employment share, block->place via `stplc`; ZBP payroll share as alternative.
  Keep public administration in numerator and denominator and flag it.
- **4e utilities (22, and 517 if in scope)** — **measured, not allocated**: city
  utility base = Albany City School District 3% utility-tax collections / 0.03.

## Conventions

- Paths via `here::here()`. Never `setwd()`.
- Sales tax year runs March-February; state fiscal year April-March. Keep the two
  straight and label every table with which one it uses.
- Write intermediates to `data/processed/` as `.rds` or `.csv`; qmd files read
  processed data and do not themselves hit the network except to verify that
  cited URLs resolve.
