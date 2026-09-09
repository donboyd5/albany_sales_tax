# Data layouts

Verified column lists for every dataset this project touches.

**Rule (CLAUDE.md #2):** before a dataset is used anywhere, its metadata or a
5-row sample is pulled, its columns recorded here, and the sample cached under
`data/raw/`. Anything in the project prompt about a dataset's schema is an
assumption to be checked against what is written below — not a fact.

Verified 2026-09-07 (Phase 1). Items marked **SURPRISE** contradict the schema
assumptions in the project prompt.

---

## 1. DTF Taxable Sales and Purchases — Socrata `ny73-2j3u`

Source: <https://data.ny.gov/Government-Finance/Taxable-Sales-And-Purchases-Quarterly-Data-Beginni/ny73-2j3u/about_data>
Endpoint: `https://data.ny.gov/resource/ny73-2j3u.json`
Metadata: `https://data.ny.gov/api/views/ny73-2j3u.json` (rows updated 2026-07-28)

| field | label | type |
|---|---|---|
| `status` | Status | text |
| `sales_tax_year` | Sales Tax Year | text |
| `selling_period` | Selling Period | text |
| `sales_tax_quarter` | Sales Tax Quarter | text |
| `jurisdiction` | Jurisdiction | text |
| `naics_industry_group` | NAICS Industry Group | text |
| `description` | Description | text |
| `taxable_sales_and_purchases` | Taxable Sales and Purchases | number |
| `jurisdiction_sort_order` | Jurisdiction Sort Order | number |
| `row_update_indicator` | Row Update Indicator | text |

Coded values:

- `sales_tax_year` — text, `"2013 - 2014"` … `"2026 - 2027"`. The sales tax year
  runs **March–February**. `"2025 - 2026"` is the latest year with all four
  quarters; `"2026 - 2027"` currently holds Q1 only.
- `sales_tax_quarter` / `selling_period` — 1 = March–May, 2 = June–August,
  3 = September–November, 4 = December–February.
- `status` — `F` (final) or `P` (preliminary). **Only through `"2023 - 2024"` is
  final.** `2024 - 2025`, `2025 - 2026` and `2026 - 2027` are all `P`.
- `naics_industry_group` — always **4 characters**; 309 distinct groups in the
  current vintage. There is no 2- or 3-digit roll-up row and no total row;
  sector totals must be built by summing 4-digit groups.

### SURPRISE 1a — no city-level rows

`jurisdiction` has **60 distinct values**: `NY STATE`, `MCTD`, `NY CITY`, and
**57 counties**. There are no city rows of any kind, so the City of Albany base
is not in this dataset and neither is the base of any of the 18 preempting
cities. City bases must come from the distributions table (§2) via the
preemption identity. Jurisdiction names are upper case with no punctuation
(`ST LAWRENCE`, not `St. Lawrence`).

### SURPRISE 1b — NAICS 2022, with a hard break at sales tax year 2022-23

The dataset switches industry-code vintage mid-series and **the back years were
not restated**:

| sales tax years | vintage | evidence |
|---|---|---|
| 2013-14 … 2021-22 | NAICS 2017 | 4541/4542/4543, 4521, 4471, 4481 present |
| 2022-23 … current | NAICS 2022 | 4551/4552, 4571/4572, 4581–4583, 4591–4599, 5162, 5171/5178 present; **no 454x at all** |

The two code sets never co-occur in a year. The project's analysis window
(2022-23 onward) is therefore entirely NAICS 2022 and internally consistent —
but see Surprise 1c.

### SURPRISE 1c — there is no nonstore/e-commerce NAICS group

NAICS 2022 eliminated sector 454 (Nonstore Retailers) and folded electronic
shopping into the store categories. **`4541` does not exist in the analysis
window.** The project prompt's §4c sourcing class ("nonstore/e-commerce")
therefore has no NAICS group to attach to: e-commerce receipts are spread
across `4551` Department Stores, `4552` Warehouse Clubs/Supercenters, `4599`
Other Miscellaneous Retailers, `4581` Clothing, and others, with no published
split. This changes the plan — see the Phase 1 report.

### NAICS 9261 is not what it looks like

`9261 Administration of Economic Programs` carries $139 M in Albany County and
**$8.5 B statewide** (the NY STATE row equals the sum of counties). Albany
County's share of the statewide figure is 1.6% — exactly its population share —
and the county distribution tracks car ownership (Suffolk 9.5%, Westchester
8.5%, NYC 32%). 9261 is the NAICS group of motor-vehicle departments; the figure
has the signature of tax collected by DMV at registration on private-party
vehicle sales, which is residence-sourced. It is classified with the
motor-vehicle class, not the business class. Inferred from the pattern, not
documented.

### Albany County base (all NAICS groups, $ billions)

| sales tax year | base | 4% of base |
|---|---:|---:|
| 2022 - 2023 | 8.983 | 359.3 M |
| 2023 - 2024 | 9.034 | 361.4 M |
| 2024 - 2025 | 9.251 | 370.0 M |
| 2025 - 2026 | 9.630 | 385.2 M |

---

## 2. DTF State and Local Sales Tax Distributions — Socrata `5g2s-tnb7`

Source: <https://data.ny.gov/Government-Finance/State-and-Local-Sales-Tax-Distributions-Beginning-/5g2s-tnb7>
Endpoint: `https://data.ny.gov/resource/5g2s-tnb7.json`
Metadata: `https://data.ny.gov/api/views/5g2s-tnb7.json` (rows updated 2025-12-05)

| field | label | type |
|---|---|---|
| `fiscal_year_ended` | Fiscal Year Ended | number |
| `taxing_jurisdiction` | Taxing Jurisdiction | text |
| `amount_distributed` | Amount Distributed | number |
| `jurisdiction_code` | Jurisdiction Sort Order | number |

- State fiscal year, **April–March**. Latest = `2025` (ended 31 Mar 2025). This
  is offset one month from the sales tax year in §1; every table must say which
  calendar it uses.
- 116 rows per year. Structure by `jurisdiction_code`: 1–3 state / NYC / MCTD,
  4–60 counties, 61–84 cities, 85–112 city consumer-utility taxes, 113–116
  special local taxes.
- Names are matched on exact prefixes: `"Albany County Sales and Use Tax"`,
  `"City of Ithaca Sales and Use Tax"`, `"Albany City School District Consumer Utilities"`.

Key rows, FY2025:

- Albany County Sales and Use Tax — **$373,153,058**
- Albany City School District Consumer Utilities — **$4,574,192**

### SURPRISE 2a — five trace cities that must be excluded

Codes 61–83 hold **23** city sales-tax rows, not 18. Five are residual amounts
from cities that repealed their taxes years ago and must be dropped:

| city | FY2025 amount | repealed (Pub 718-A) |
|---|---:|---|
| Corning | $498 | 1 Mar 2015 |
| Fulton | $123 | 1 Mar 2007 |
| Geneva | $425 | 1 Mar 2006 |
| Hornell | $614 | 1 Mar 2015 |
| Sherrill | $194 | 1 Sep 2008 |

23 − 5 = **18**, exactly matching the OSC list in the project prompt.

### SURPRISE 2b — Yonkers has two rows

`City of Yonkers Sales and Use Tax` ($83,381,305) **and** `City of Yonkers
Special Sales and Use Tax` ($41,694,668). The ratio is exactly 2.000, consistent
with a 3% + 1.5% split of the city's 4.5% rate. Both rows must be summed to get
`C_c` for Yonkers.

---

## 3. Rates — DTF Publications 718, 718-A, 718-C

All three PDFs fetched successfully (HTTP 200), text extracted with `pdftotext -layout`.

- Pub 718 (2/25), effective 1 Mar 2025: <https://www.tax.ny.gov/pdf/publications/sales/pub718.pdf> — **combined** state+local rate by jurisdiction.
- Pub 718-A (12/25): <https://www.tax.ny.gov/pdf/publications/sales/pub718a.pdf> — enactment/effective dates and **separate** county and city rates.
- Pub 718-C (2/25): <https://www.tax.ny.gov/pdf/publications/sales/pub718c.pdf> — clothing/footwear exemption.

**Albany County: 4%**, effective 1 Sep 1992, flagged `C` (current) in Pub 718-A.
Combined Albany rate 8% in Pub 718.

### Pub 718-C — Albany County does NOT exempt clothing

Part 1 (jurisdictions providing the under-$110 clothing and footwear exemption)
lists only: Chautauqua, **Chenango (outside the city of Norwich)**, Columbia,
Delaware, Dutchess, Greene, Hamilton, Monroe, Putnam, Tioga counties, and New
York City. **Albany County is not on the list**, so the hypothetical city add-on
base equals the county base with no clothing adjustment. (Note for §6: the
Chenango carve-out means Norwich city and the rest of Chenango have *different*
bases — a calibration complication for that one city.)

### SURPRISE 3a — `p_c = r_c`, not 1.5

Pub 718 publishes the combined rate **inside** each preempting city and for the
county "– except" that city. For **every city except Yonkers these are equal**,
which pins the preempted amount exactly:

    combined_in  = 4 (state) + MCTD + (r_k − p_c) + r_c
    combined_out = 4 (state) + MCTD + r_k
    ⇒ p_c = r_c − (combined_in − combined_out)

So `p_c = r_c` for 17 of 18 cities. The project prompt's `p_c default 1.5` is
wrong wherever `r_c ≠ 1.5`. Yonkers is the one exception: combined 8⅞ inside vs
8⅜ outside, a **+0.5 point differential**, giving `r_c = 4.5, p_c = 4.0`.

Pub 718-A's lettered footnotes ("within city, county rate is 1½%") are historical
accretions and could not be reliably matched to rows from the two-column PDF text
layer; they conflict with Pub 718's combined rates in several places. **Pub 718's
combined rates are used as the authority**, and the result is confirmed
empirically in §6 below.

### SURPRISE 3b — Pub 718-A's percentage column is NOT the imposed city rate

**This was initially misread and the correction matters: taking the 718-A
percentage column at face value doubles the estimated base for five cities and
moves the Route B median from 0.74 to 1.06.**

Publication 718-A lists, in its city table, a percentage that for six cities is
not the rate the city actually imposes. Its own header warns: "The rates
indicated cannot be added to determine the combined state, county, and city tax
rate. Refer to Publication 718 … for the combined rates."

Three independent sources agree against that column:

1. **Pub 718** gives the combined rate *inside* each city, which fixes
   `county-in-city + r_c` exactly.
2. **Pub 718-A's own lettered footnotes** give the county's rate inside the
   city — `a` "City preempts county tax rate. Within city, county rate is 1½%
   (not counting any additional rate)", `c` "Within city, county tax rate is
   1½%", `t` "…county rate is 2%", `m` "Additional 1% not subject to
   preemption". Subtracting each from the Pub 718 combined rate reproduces the
   OSC value in every case.
3. **OSC (2020), Figure 2**, "City Portion of the Local Rate", sourced to DTF.

| city | 718-A % column | **rate used** | p_c | agreement |
|---|---:|---:|---:|---|
| Auburn | 2.0 | **2.0** | 2.0 | all sources |
| Glens Falls | 1.5 | **1.5** | 1.5 | all sources |
| Gloversville | 3.0 | **2.0** | 2.0 | OSC + footnote t + Pub 718 |
| Ithaca | 1.5 | **1.5** | 1.5 | all sources |
| Johnstown | 3.0 | **2.0** | 2.0 | OSC + footnote t + Pub 718 |
| Mount Vernon | 2.5 | **2.5** | 2.5 | all sources |
| New Rochelle | 3.0 | **2.5** | 2.5 | OSC + footnote m + Pub 718 |
| Norwich | 3.0 | **1.5** | 1.5 | OSC + footnote a + Pub 718 |
| Ogdensburg | 3.0 | **3.0** | 3.0 | city code (§1210(a)) + §1224 + DTF ST-22-1 — **corrected 2026-09-08**, see below |
| Olean | 1.5 | **1.5** | 1.5 | all sources |
| Oneida | 2.0 | **2.0** | 2.0 | all sources |
| Oswego | 4.0 | **4.0** | — | excluded, see §6 |
| Rome | 1.5 | **1.5** | 1.5 | all sources |
| Salamanca | 1.5 | **1.5** | 1.5 | all sources |
| Saratoga Springs | 3.0 | **1.5** | 1.5 | OSC + footnote c + Pub 718 |
| Utica | 1.5 | **1.5** | 1.5 | all sources |
| White Plains | 2.5 | **2.5** | 2.5 | all sources |
| Yonkers | 4.5 | **4.5 total** | **4.0** | see below |

The rates used match the OSC seed table in the project prompt exactly, except
Yonkers. The prompt's `p_c default 1.5` is still wrong: **`p_c = r_c` for every
city but Yonkers**, forced by Pub 718 publishing the same combined rate inside
and outside each city.

**Ogdensburg — corrected.** It repealed in 2000 and re-imposed effective
1 March 2022, so it is absent from OSC's January 2020 table. An earlier reading
inferred 1.5% from footnote `a` by analogy with Norwich; that was wrong. The city
code imposes **3%** under Tax Law §1210(a); the city preempted the county's base
3% within the city, and St. Lawrence retains only its additional 1%, which is not
subject to preemption under §1224. County-in-city 1% + city 3% = 4% local,
matching Pub 718's combined 8% and DTF notice ST-22-1 ("the rates to charge in
the county and city remain the same"). Its base is therefore \$71 M, not
\$142 M, and its R is 0.35. For this one city Pub 718-A's percentage column
was right.

**Yonkers.** Pub 718 gives 8⅞% inside the city against 8⅜% outside — a
**+0.5 point differential**, the only one in the state — the economic analog
for Albany's proposed differential, but not a legal precedent for it, because
Yonkers' extra half point sits on top of full preemption (see the memo, §1). The city
takes the county's full 4% and imposes 4.5%. Its two distribution rows stand in
an exact 2.000 ratio (3.0% regular + 1.5% special), so its base is identical
whether computed as total ÷ 4.5% or regular ÷ 3.0% — Yonkers is immune to the
rate ambiguity above. OSC's Figure 2 lists 3.0 for Yonkers, the regular portion
only.

County rates (Pub 718 combined − 4% state − ⅜% MCTD where starred): Cayuga 4,
Cattaraugus 4, Chenango 4, Fulton 4, Madison 4, Oneida 4.75, Oswego 4,
St. Lawrence 4, Saratoga 3, Tompkins 4, Warren 3, Westchester 4.

Ogdensburg's re-imposition effective 1 Mar 2022 falls at the very start of the
analysis window, so its rate applies throughout FY2023–FY2025.

---

## 4. TSB-M-90(6)S — Albany City School District utility tax

<https://tax.ny.gov/pdf/memos/sales/m90_6s.pdf> (HTTP 200)

Resolves the open question in §4e of the prompt: the ACSD 3% tax covers **both**
utilities **and** telecommunications —

> gas, electricity, refrigeration and steam … and telephony and telegraphy and
> telephone and telegraph service of whatever nature, except interstate and
> international …

within the city of Albany, effective 1 Sep 1990. So the county comparator must be
**NAICS 22 + 517**, not NAICS 22 alone.

### SURPRISE 4a — the ACSD base is not the county base at a different rate

The memo also states that residential gas/electric/steam is **exempt from the
state tax and taxed by Albany County at a reduced 1%**, while the ACSD taxes it
at the full 3%. Numerator (ACSD collections ÷ 0.03) and denominator (county
NAICS 22+517 taxable sales) therefore cover somewhat different mixes, and a
hypothetical city add-on would need its own residential-energy election under
§1210. The ratio is still the only directly observed city/county base share
available, but it is not a clean apples-to-apples measurement and must be
labelled as such.

### First observed city/county base share

FY2025 ACSD collections $4,574,192 ÷ 0.03 = **$152.5 M city utility base**.
Albany County 2024-25 NAICS 22 + 517 taxable sales = **$295.2 M**
(22: $202.0 M — 2211 $194.1 M, 2212 $7.1 M, 2213 $0.8 M; 517: $93.2 M —
5171 $84.8 M, 5174 $0.1 M, 5178 $8.3 M).

**a_utilities = 0.517** against 22+517 (0.755 against NAICS 22 alone), versus a
population share of 0.317 → implied **R ≈ 1.64**.

---

## 5. 2022 Economic Census — Census API `ecnbasic`

Dataset: <https://api.census.gov/data/2022/ecnbasic.html>
Variables: <https://api.census.gov/data/2022/ecnbasic/variables.html>

Geography levels available (`geography.json`): `us` 010, `region` 020, `state`
040, `county` 050, `consolidated city` 170, `metropolitan statistical
area/micropolitan statistical area` 310, `metropolitan division` 314, `combined
statistical area` 330, **`economic place` E60**, **`economic place (or part)` E65**.

### SURPRISE 5a — `economic place` codes are 8 digits, not 5

The prompt's example query pattern works, but `economic place:01000` returns
**HTTP 204 (empty)**. The code is a 3-digit prefix + the 5-digit place FIPS:

- Albany city = **`00101000`**
- Cohoes city = `00116749`, Watervliet city = `00178674`,
  Colonie village = `00117332`, Colonie town (balance) = `00117343`,
  Guilderland town = `00131104`, Bethlehem town = `00106354`,
  Menands village = `00146536`

786 economic places are published for state 36. Codes must be discovered from a
`for=economic place:*` listing, never constructed from place FIPS.

### Retail (NAICS 44-45) coverage check, 2022, RCPTOT $ thousands

| place | RCPTOT |
|---|---:|
| Albany city | 2,238,425 |
| Colonie town (balance) | 4,301,988 |
| Colonie village | 580,261 |
| Bethlehem town | 520,008 |
| Guilderland town | 471,071 |
| Cohoes city | 195,147 |
| Watervliet city | 86,056 |
| Menands village | 36,241 |
| **sum of places** | **8,429,197** |
| **Albany County** | **8,628,380** |
| residual (unincorporated/suppressed) | 199,183 (2.3%) |

Place coverage of the county is excellent. **Albany city's share of county retail
receipts is 25.9% — below its 31.7% population share.**

---

## 6. Empirical validation of the preemption identity

Test: if `p_c = r_c`, then `C_k + Σ_i C_i = r_k × B_k` (the rates cancel, so this
tests the identity jointly and is *insensitive* to the individual `r_c` values).
Sales tax year 2024-25 base vs FY2025 distributions (one month offset).

| county | (C_k + Σ p_i B_i) ÷ (r_k B_k) |
|---|---:|
| Cattaraugus | 0.999 |
| Cayuga | 1.002 |
| Chenango | 1.017 |
| Fulton | 0.977 |
| Madison | 0.985 |
| Oneida | 0.971 |
| **Oswego** | **0.638** |
| Saratoga | 0.995 |
| St. Lawrence | 0.936 |
| Tompkins | 0.997 |
| Warren | 0.989 |
| Westchester | 0.976 |

Eleven of twelve reconcile within 1–6% on single-year figures, and within
0.995–1.027 on the three-year mean once the verified rates of §3b are used. This
simultaneously confirms that (a) the `ny73-2j3u` county base covers the **whole
county including preempting cities**, and (b) the preemption structure. Note the
test is insensitive to the rate *level* wherever `p_c = r_c`, so it validates the
structure but cannot by itself settle §3b.

### SURPRISE 6a — Oswego cannot be reconciled

For Oswego, county collections alone equal essentially **100% of 4% × the county
base in every year 2014–2025** (ratio 0.96–1.05), with the city's collections
entirely additive on top (county+city ÷ 4%×base = 1.25–1.38). Three published
facts are mutually inconsistent under any single interpretation:

1. Pub 718 gives 8% combined both inside and outside the city (⇒ `p_c = 4`);
2. county collections behave as if `p_c = 0`;
3. the city collects a further $23.2 M (FY2025).

Per §6 of the prompt, Oswego is **reported separately and excluded from summary
statistics**.

---

## 7. ACS 5-year (2023) — `censusapi` / Census API

`https://api.census.gov/data/2023/acs/acs5` — `place:01000 in state:36` and
`county:001 in state:36` (ordinary 5-digit place FIPS here, unlike `ecnbasic`).

| variable | Albany city | Albany County | share |
|---|---:|---:|---:|
| `B19025_001E` aggregate household income | 3,511,073,300 | 14,303,090,600 | **0.2455** |
| `B11001_001E` households | 43,745 | 132,728 | **0.3296** |
| `B01003_001E` population | 100,081 | 315,374 | **0.3173** |

Note the income share (24.6%) sits well below the household share (33.0%) —
Albany city has more, smaller, lower-income households than the county average.
The choice between them moves the §4c delivered-goods allocator by a third.

---

## 8. LEHD LODES

<https://lehd.ces.census.gov/data/lodes/LODES8/ny/> — HTTP 200.
Latest WAC vintage available: **2023** (`ny_wac_S000_JT00_2023.csv.gz`), one year
newer than the prompt's assumed 2022. Crosswalk `ny_xwalk.csv.gz` present
(carries the `stplc` place field).

### SURPRISE 8a — `lehdr::grab_lodes()` has no place aggregation

`lehdr` 1.2.0 `agg_geo` accepts only `block`, `bg`, `tract`, `county`, `state`.
Place-level aggregation must be done manually: pull WAC at block level, join
`ny_xwalk.csv.gz` on the 2020 block id, and sum by `stplc`.

---

## 9. County/ZIP Business Patterns

### SURPRISE 9a — ZBP as a separate API ends at 2018

`https://api.census.gov/data/<year>/zbp` returns HTTP 200 for 2017 and 2018 and
**404 for 2019 onward**. The prompt's "latest vintage" ZBP fallback does not
exist.

**Replacement:** `cbp` 2023 carries geography level **861 `zip code`**, so the
ZIP-level payroll fallback runs through CBP instead:
`https://api.census.gov/data/2023/cbp?get=ESTAB,PAYANN,EMP&for=zip code:12203&NAICS2017=00`

Two caveats:

- **CBP 2023 still uses `NAICS2017`**, not NAICS2022 — a different vintage from
  both the Economic Census allocator and the DTF base. Any fallback crossing
  this boundary must be flagged in the output table.
- ZIP × detailed-NAICS cells are heavily suppressed: ZIP 12203 total (NAICS 00)
  returns ESTAB 892 / PAYANN 1,304,395 / EMP 18,450, but NAICS 44-45 for the same
  ZIP returns ESTAB 186 / **PAYANN 0 / EMP 0**. The fallback is usable only at
  coarse NAICS levels.

CBP has **no `place` geography** (levels: us, state, county, MSA, CSA,
congressional district, zip code), so ZIP → place allocation is unavoidable.

### ZCTA-to-Place relationship file (2020)

<https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_place20_natl.txt>
— HTTP 200, plain text.

---

## 10. DMV Vehicle, Snowmobile and Boat Registrations — Socrata `w4pv-hbkt`

Source: <https://data.ny.gov/Transportation/Vehicle-Snowmobile-and-Boat-Registrations/w4pv-hbkt>
Metadata rows updated 2026-09-02. **12.5 M rows — never downloaded whole**; all
access is via SoQL `$select`/`$group`.

Fields: `record_type`, `vin`, `registration_class`, `city`, `state`, `zip`,
`county`, `model_year`, `make`, `body_type`, `fuel_type`, `unladen_weight`,
`maximum_gross_weight`, `passengers`, `reg_valid_date`, `reg_expiration_date`,
`color`, `scofflaw_indicator`, `suspension_indicator`, `revocation_indicator`.

- `record_type` values: `VEH` (11,377,388), `TRL` (803,775), `BOAT` (358,172),
  `SNOW` (5,945). Filter to `VEH`.
- **`county` is UPPER CASE** — `"ALBANY"`, not `"Albany"`. A mis-cased filter
  silently returns zero rows.
- `model_year` is numeric and runs ahead of the calendar (2027 models present).
  Albany County `VEH` counts: MY2023 14,573 / 2024 17,687 / 2025 18,862 /
  2026 15,547 / 2027 496.

### SURPRISE 10a — `city` is the mailing address, and fleet registrations are large

Top Albany-County `VEH` cells (MY ≥ 2024) by `city, zip`:

| city | zip | n |
|---|---|---:|
| ALBANY | 12205 | 5,240 |
| LATHAM | 12110 | 4,677 |
| ALBANY | 12203 | 3,887 |
| COHOES | 12047 | 3,382 |
| DELMAR | 12054 | 2,995 |
| **FT LAUDERDALE** | **33309** | **2,239** |
| **PORT NEWARK** | **07114** | **2,197** |

Two problems:

1. `city` is the **postal** city, not the municipality. ZIP 12205 is largely the
   town of Colonie and 12203 straddles Albany city and Guilderland, yet both
   carry the city name "ALBANY". Confirms the prompt's warning: assign through
   the ZCTA–Place relationship file, never whole ZIPs, and never trust `city`.
2. Out-of-state ZIPs (Ft Lauderdale FL, Port Newark NJ) carry ~4,400 MY≥2024
   Albany-County registrations — leasing and fleet registrants. These have no
   in-county residence to allocate and must be handled explicitly, not silently
   dropped into a ZIP match that fails.


---

## 11. OSC, *Understanding local government sales tax in New York State: 2020 update*

<https://www.osc.ny.gov/files/local-government/publications/pdf/understanding-local-government-sales-tax-in-nys-2020-update.pdf>
— HTTP 200, 1.98 MB.

Figure 2, "City Sales Tax Rates, as of January 1, 2020", gives for each
preempting city the combined rate and the **City Portion of the Local Rate**,
sourced to DTF. This is exactly `r_c`, and it is the authority used for §3b
above. The report also documents each county's distribution formula, which
Phase 3 needs to verify the 0.40 factor in Albany's break-even calculation.


---

## 12. Publication 718-R — local rates on residential energy (verified 2026-09-09)

<https://www.tax.ny.gov/forms/publications/st/pub718r.htm> — HTML page, HTTP 200
(the `.pdf` path returns 404). Edition "(5/26)", effective 1 June 2026.

Structure: Part 1 lists jurisdictions taxing residential gas, propane,
electricity and steam; Part 2 lists those taxing residential coal, fuel oil and
wood. "Localities or school districts not listed in this publication do not
impose a local tax on residential energy sources and services."

**Albany County appears in neither part.** Part 1 lists "Albany School District
(Albany County) 3", "Cohoes School District (Albany County) 3" and "Watervliet
School District (Albany County) 3". Consequences:

- The county's published taxable sales for NAICS 22 (utilities) and 4247
  (petroleum wholesalers, i.e. heating oil) contain no residential energy.
- The Albany City School District's collections DO include residential
  energy at 3%, so `ACSD / 0.03` over county NAICS 22+517 overstates the
  comparable city share; the 48.9% measured share is an upper bound.
- TSB-M-90(6)S's statement that the county taxed residential energy at 1%
  described 1990 and is no longer current.

### 12a. What the county row contains (verified 2026-09-09)

Question raised in review: is `ny73-2j3u` the base subject to the *state* 4%
(residential energy excluded everywhere) or the base on each jurisdiction's
line of the return (residential energy included where a local tax applies)?

- DTF's dataset page (`research/stats/stat_excise/taxable_sales_and_purchases/
  taxable_sales_and_purchases_open_data.htm`) says: "taxable sales and
  purchases subject to State, Metropolitan Commuter Transportation District,
  County, and New York City (NYC) sales tax." No school district taxes.
- Schedule B instructions (ST-100.3-I, `pdf/current_forms/st/st100_3i.pdf`):
  residential gas/electric/steam go in Part 1 and residential heating fuels in
  Part 2, "for each jurisdiction", at the jurisdiction's own rate; only
  nonresidential utilities in localities *not* listed in Part 3 go on the
  ordinary ST-100 Step 3 jurisdiction lines.
- Cross-county test (R/06_results.R, `re_test`, crosswalk
  `data/crosswalk/pub718r_residential_energy.csv`): median utilities (NAICS 22)
  base per person, FY2023-25, is $1,247 in the 13 counties that tax
  residential energy, $597 in the 28 with no local tax, $470 in the 16 where
  only a school district or city taxes it; whole base per person is the same
  across groups. Albany: $685.

Conclusion: the county row includes residential energy only where the
**county** taxes it. Albany County's utilities and 4247 figures exclude
residential energy; the ACSD measurement (which includes it at 3%) is an
upper bound of the comparable share. The old memo sentence that the county
figure was "commercial because the county does not tax it" was right in
effect but for an incompletely stated reason; the reasoning is now recorded.


---

## 13. Collections ÷ rate against reported taxable sales, all counties (2026-09-09)

Reviewer's point: the city base inferred as collections ÷ rate is itself an
estimate (rate errors, partial-year rates, base definitions, audits and
delinquencies, corrected distributions). Tested where both quantities are
published: 57 counties × FY2023–2025 (`R/06_results.R`, `county_test`), with
county rates transcribed from Pub 718 (2/25) into
`data/crosswalk/county_rates_pub718.csv` (combined rate less 4% state, less
3/8% MCTD in the seven MCTD counties) and preempted city amounts added back.

Result: median ratio 1.005, SD 0.021, 97% of county-years within 5% of 1, all
within 10%; median year-to-year swing 2.5 points. Low outliers are the
counties taxing residential energy at a rate below their general rate
(Suffolk 0.954, Franklin 0.975, Tioga 0.982), consistent with §12a; Niagara
(0.936) is unexplained. Oswego reconciles at 1.017 with `p_c = 0` for the
city (the earlier finding that county collections equal 4% of the whole
county base, i.e. the city tax is additive in the data).

City shares (`city_stability`): swing across FY2023–25 under 6% for most
cities, 13% for Ogdensburg (new code), 9% Norwich, 8% Glens Falls.

"Best-supported" calibration subset (`TRUST_CITIES`): rate agreed by every
source and swing under 10%, excluding the two structural exclusions.


---

## 14. ORPTS assessment rolls — Socrata `7vem-aaz7` (verified 2026-09-09)

<https://data.ny.gov/Government-Finance/Property-Assessment-Data-from-Local-Assessment-Rol/7vem-aaz7>
103 columns; 4.7 M parcels; latest `roll_year` 2025. Key fields: `county_name`,
`municipality_name`, `municipality_code` (six digits; third-fourth digits below
20 are cities, e.g. Albany 010100, Cohoes 010300, Watervliet 011800; towns
012000+), `roll_section` (1 ordinary taxable, 3 state-owned land, 5/6/7
special franchise etc., 8 wholly exempt), `property_class` (ORPTS 3-digit),
`property_class_description`, `full_market_value` (equalized), `assessment_total`,
`county_taxable_value`, ten exemption code/amount slots. Pulled only as
server-side aggregates (`roll_by_class` in R/03) for the 12 analysis counties.

SURPRISE 14a: `full_market_value` is zero or implausible for most Westchester
municipalities (Mount Vernon, Rye, Greenburgh, Harrison, Ossining, Yorktown 0;
White Plains $0.79 B on 14,044 parcels), so no full-value measure exists for
the four Westchester calibration cities; the assessed-value allocator returns
NA for them. Other counties' fmv/av ratios are sensible (Tompkins 1.00, Albany
1.50, Oneida 2.50).

Albany city 2025: roll section 1 commercial (4xx) $2.28 B FMV, industrial
$0.05 B; roll section 8 $7.0 B of community-service property (652 office
buildings $3.19 B = state offices, 613 colleges $1.27 B, 641 hospitals $0.65 B,
612 schools $0.35 B, 620 religious $0.29 B).
