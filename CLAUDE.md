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
| `R/05_calibrate.R`      | section A: Route B reduced form; section B: observed vs predicted base, log-log fit, residual SD, band; section C: diagnostics |
| `R/06_results.R`        | computes every number the book reports into `data/processed/results.rds`; every chapter reads that file via `chapters/_common.R`. Re-run after any data or code change, then `make render` |
| `R/99_check_urls.R`     | verifies every cited URL still resolves |

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
- **Phase 3** Apportionment, calibration, revenue estimate -> `analysis/city-halfpct-revenue.qmd`. **DONE.**

Run `Rscript R/99_check_urls.R` before publishing: it re-checks every URL cited
in the qmd files and crosswalks. Statutes are cited by section, not URL, because
the legal aggregators (doi.org, findlaw, justia, nysenate) return 403 to
non-browser clients and so cannot be verified programmatically.

## Sourcing classes (Phase 3)

Every NAICS group in the DTF county table maps to exactly one class, recorded in
`data/crosswalk/naics_sourcing_class.csv` with a `rationale` column:

- **4a store-based** — allocator: 2022 EC `RCPTOT` at `economic place`, finest
  unsuppressed NAICS level; fall back to `PAYANN`, then ZBP payroll; record the
  fallback per group.
- **4b motor vehicles (4411, 4412, and 9261)** — sourced to purchaser residence
  (Tax Law s.1214; Pub 838; Form DTF-802); allocator: DMV registrations by
  county x ZIP, split ZIP->place by 2020 block population (block->place from the
  Block Assignment Files, block->ZCTA from the relationship file). 4413 parts and
  tires stay store-based. 9261 is included because its $8.5B statewide is
  distributed like population/car ownership -- DMV-collected tax on private
  vehicle sales, not state-agency vendor activity.
- **4c delivered-to-residence** — nonstore/e-commerce plus the delivered half of
  furniture/appliance/building-material groups; allocator: ACS B19025 aggregate
  household income share (central), B11001 household share (sensitivity).
- **4d business purchases and use tax** — taxable sales of business-serving
  vendors sourced to the customer's location. Allocator: LODES WAC 2023
  workplace employment share **excluding public administration** (governments
  are exempt purchasers, Tax Law s.1116(a)(1)); total employment and EC payroll
  as sensitivities. The plan's original "state government is a large taxable
  purchaser" premise was wrong and was corrected 2026-09-08.
- **4e utilities (22 **and** 517 — TSB-M-90(6)S confirms the school district tax
  covers telecom)** — allocated by workplace employment in the generic
  apportionment so the calibration can run on every city; the ACSD measurement
  (city base = collections / 0.03) is used as validation 3: the measured share
  (48.9%) lies between the private-employment allocator (42.8%) and total
  employment (52.9%), closer to the latter. State utility purchases are exempt
  and appear in neither figure, so this is taxable commercial load, not
  evidence for counting government jobs.

## Phase 3 headline

Revenue approximately **$11.1 M/year**, 68% band $9.2-13.5 M, 90% $8.1-15.3 M;
planning range $8-15 M (computed envelope), budget figure $11 M. B_c calibrated
= $2.21 B, R = 0.77.

Calibration: the preferred fit drops Salamanca (100% on Seneca Nation Allegany
Territory, Census AIANNH 0080) and Ogdensburg (jurisdiction code created 1 Mar
2022, implied share still ramping 3.01->3.45%; border-traffic collapse) --
CALIB_EXCLUDE in R/05_calibrate.R. Both have verified reasons that do not
transfer to Albany. n=15, beta 0.881 (se 0.033), sigma 0.192, R2 0.954. All-17
fit gives $12.5 M with sigma 0.453 and is reported alongside.

County fixed effects explain 83% of the variance in log(obs/pred) but are not
predictable from county characteristics. Four mechanisms make the apportionment
overstate a city's base: vendors coding sales to the county rather than the
city (invisible to the preemption identity); capital-intensive plants/resorts
outside cities that employment cannot see; Economic Census receipts being gross
rather than taxable; exempt hospitals and universities inside cities.

Rate correction 2026-09-08: Ogdensburg is 3.0%, not 1.5% -- the city code
imposes 3% under s.1210(a), preempting the county's base 3%, with St. Lawrence
retaining only its non-preemptable additional 1% (s.1224). Saratoga Springs
confirmed at 1.5% by the Saratoga County Treasurer.

## The write-up is a Quarto book (2026-09-09)

`_quarto.yml` is `type: book`. Chapters live in `chapters/` (01 policy option,
02 approach, 03 data, 04 apportionment -- the deep dive on classes, the
business class by customer type, and what is inside the employment allocator
-- 05 calibration, 06 results, 07 alternatives, 08 sensitivity, 09 checks /
preemption / timing, 10 limitations and recommendations, references) and
appendices in `appendices/` (glossary, the Route B benchmark, the original
technical report, reproducing). `analysis/` and the memo markdown are gone;
their content is in the chapters. Chapters use plain language for a policy
analyst: "sharing rule" for allocator, "division of the county base" for
apportionment, "typical miss" for sigma. Keep that register.

Business-class facts established 2026-09-09: the class is 26% of the county
base; by a customer-type reading (business_customer_type() in R/04), 58% is
mostly sold to businesses, 38% mixed, 5% mostly households. The city's 42.8%
share of private jobs is driven by health care (28% of city private jobs),
education (15%), professional services and finance; the city has only 21% of
manufacturing, 28% of wholesale and 29% of transportation jobs. Alternatives
(business locations 35.6%, ex-exempt 35.6%, customer split 38.5%) give
$10.5-10.9 M with the calibration re-fitted; payroll 47.9% gives $11.8 M. Across
the 15 calibration cities, the job-minus-population gap does not predict
over-prediction (slope -0.42, p 0.52). Pub 718-R: Albany County does NOT tax
residential energy (only the three school districts do, at 3%), so the ACSD
utility measurement (48.9%) is an upper bound of the comparable share.
