# Albany City 0.5% add-on sales tax — revenue estimate

**Published site:** <https://donboyd5.github.io/albany_sales_tax/> ·
**Memo:** [`docs/albany-halfpct-memo.md`](docs/albany-halfpct-memo.md)

A reproducible estimate, with an error band, of the annual revenue the City of
Albany, NY would raise from a hypothetical **0.5 percentage-point add-on sales
and use tax** imposed on the same base Albany County taxes at 4%,
destination-sourced, layered on the existing 8% combined rate — no preemption of
the county tax, no change to county distributions.

    Revenue = 0.005 x B_c x (1 - phi) x beta

where `B_c` is the City of Albany taxable sales base, `phi` the administrative
deduction, and `beta` a behavioral factor for the 0.5-point rate differential at
the city line.

`B_c` is not published by anyone. It is estimated by NAICS-group apportionment of
the *observed* Albany County base, and that apportionment is calibrated against
the 18 New York cities outside NYC that levy their own sales tax — cities whose
own base is recoverable from published distributions.

## Reproducing

```bash
git clone <this repo>
cd albany_sales_tax
```

1. **Restore the R environment**

   ```r
   renv::restore()
   ```

2. **Add your Census API key.** Get one at
   <https://api.census.gov/data/key_signup.html>, then

   ```bash
   cp .Renviron.example .Renviron
   # edit .Renviron: CENSUS_API_KEY=<your key>
   ```

   Restart R so the key is loaded. `.Renviron` is git-ignored; never commit it.

3. **Run the pulls** (they cache into `data/raw/` and are skipped if present)

   ```r
   source("R/00_setup.R")
   source("R/01_pull_dtf.R")
   source("R/02_pull_census_ec.R")
   source("R/03_pull_acs_lodes_dmv.R")
   source("R/04_allocate.R")
   source("R/05_calibrate.R")
   ```

4. **Render**

   ```bash
   quarto render                                   # or: make render
   cp _output/analysis/memo.md docs/albany-halfpct-memo.md
   ```

   The site (`index.html` plus the three documents) lands in `_output/`; the
   memo is also rendered to GitHub-flavored Markdown and kept at
   `docs/albany-halfpct-memo.md`. `make publish` pushes the rendered site to
   the `gh-pages` branch, from which GitHub Pages serves it.

## Layout

```
R/                  pull, allocate and calibrate scripts (see CLAUDE.md for roles)
data/raw/           cached source pulls + MANIFEST.csv (file, source_url, pulled_at, sha256)
data/processed/     tidied intermediates
data/crosswalk/     hand-built mapping tables; each carries a `source` column with a URL
docs/data-layouts.md   verified column lists for every dataset used
index.qmd           landing page for the published site
analysis/memo.qmd   the write-up: policy option, goals, data, method, results, alternatives, sensitivity
analysis/route-b.qmd            17-city reduced-form benchmark
analysis/city-halfpct-revenue.qmd   the technical estimate
docs/albany-halfpct-memo.md     the memo, rendered to Markdown (generated -- edit analysis/memo.qmd)
docs/meta_notes.md              notes for a reviewer: judgment calls, corrections made, dead ends, verification status
docs/data-layouts.md            verified schema of every dataset, and where it differed from what was assumed
```

## Ground rules

Every number in the rendered documents traces to a cached raw file and a script.
The only hand-entered figures are the crosswalk tables, which cite a URL per row.
Dataset schemas are verified against live metadata before use, not assumed.
Details in `CLAUDE.md`.

## Data sources

- NYS DTF, Taxable Sales and Purchases (Socrata `ny73-2j3u`)
- NYS DTF, State and Local Sales Tax Distributions (Socrata `5g2s-tnb7`)
- NYS DTF, AS001 revenue distribution certifications
- NYS DTF, Publications 718 / 718-A / 718-C (rates)
- U.S. Census Bureau, 2022 Economic Census (`ecnbasic`), ACS 5-year, CBP/ZBP, decennial PL
- U.S. Census Bureau, LEHD LODES WAC
- NYS DMV, Vehicle, Snowmobile and Boat Registrations (Socrata `w4pv-hbkt`)

Full citations with URLs appear in the rendered analysis documents.
