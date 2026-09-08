# A 0.5% City of Albany add-on sales tax: policy option, method, data, and findings

2026-09-08

- [Summary](#summary)
- [Overview: how the estimate was made, in one page](#overview-how-the-estimate-was-made-in-one-page)
- [1. The policy option](#1-the-policy-option)
- [2. Goals](#2-goals)
- [3. Why the estimate is hard](#3-why-the-estimate-is-hard)
- [4. Data](#4-data)
- [5. Methods](#5-methods)
- [6. Results](#6-results)
- [7. A reasonable range, and how it relates to the statistical band](#7-a-reasonable-range-and-how-it-relates-to-the-statistical-band)
- [8. Alternative methodologies](#8-alternative-methodologies)
- [9. Sensitivity analysis](#9-sensitivity-analysis)
- [10. Validations](#10-validations)
- [11. The preemption comparison](#11-the-preemption-comparison)
- [12. Timing and first-year cash](#12-timing-and-first-year-cash)
- [13. Limitations](#13-limitations)
- [14. Recommendations](#14-recommendations)
- [References](#references)

*Generated 08 September 2026 from `analysis/memo.qmd`. Every number below is computed at render time from the cached source pulls in `data/raw/` (provenance in `data/raw/MANIFEST.csv`); the two crosswalk tables in `data/crosswalk/` are the only hand-entered inputs and each row cites its source. The full technical reports with figures are `_output/analysis/city-halfpct-revenue.html` and `_output/analysis/route-b.html`.*

## Summary

|  |  |
|----|----|
| **Policy option** | A 0.5 percentage-point City of Albany sales and use tax, added on top of the existing 8% (4% state, 4% county), on the same base the county taxes, destination-sourced, with no preemption of the county tax and no change to county distributions. |
| **Central estimate** | **\$12.2 million a year** at 2022–2025 activity levels; about **\$12.9 million** at the latest full year (2025 - 2026) |
| **Upper case** | **\$13.4 million** if government jobs are counted in the allocator for business purchases (§9.1); the central case leaves them out because governments are exempt purchasers |
| **City taxable base** | **\$2.42 billion**, 26.7% of the county’s \$9.09 billion, against a 31.5% population share |
| **Reasonable planning range** | **\$10–15 million** (base \$2.0–3.0 billion) — see §7 for how this differs from the statistical band |
| **Statistical band** | 68%: \$8.4–17.7 M; 90%: \$6.6–22.5 M |
| **Largest uncertainty** | How to treat the city’s very large public sector. Government purchases are exempt from sales tax, so government jobs are left out of the allocator for business purchases; counting them would add about \$1.2 M. The 17 cities the method is checked against have too little government employment to settle it either way. |
| **Against what the city receives now** | The city’s population-based share of the county tax is about \$46.2 M a year; the add-on would add \$12.2 M on top of it (+26%) without touching it |
| **Preemption comparison** | Preempting 1.5 points instead would yield \$36.4 M against the \$46.2 M it would forfeit — a loss of about \$9.8 M a year |

## Overview: how the estimate was made, in one page

**The question.** A 0.5% city tax raises 0.5% of whatever is sold taxably inside the city. So the job is to estimate the city’s taxable sales — the *base* — and multiply.

**The problem.** The Tax Department publishes taxable sales for Albany *County* (\$9.09 billion a year, broken into 302 industry groups) but not for the City, because the City has no sales tax to report on. Nobody publishes the city figure.

**The approach**, in six steps:

1.  **Start from the county’s taxable sales by industry** (Tax Department, `ny73-2j3u`), averaged over the three most recent complete sales tax years.
2.  **Sort the industry groups into five classes by where the tax law says the sale is taxed.** Sales over the counter (stores, restaurants, hotels, personal services) are taxed where the store is. Taxable goods and services bought by *businesses* — cleaning and security, software, repair and maintenance, equipment — are taxed where the buying business operates. (Governments are exempt from sales tax, so their purchases are not in the base at all.) Cars are taxed where the *buyer lives*, not where the dealer is. Delivered goods (furniture, appliances, building materials) are taxed where they are delivered. Utilities and telephone service are taxed where they are used.
3.  **For each class, measure the city’s share of the county with the public data that best matches that rule.** Where the stores are: the 2022 Economic Census (Albany city has 25.9% of county retail receipts). Where the private-sector employers are: Census LODES employment data, leaving out government jobs because government is an exempt purchaser (the city has 42.8% of the county’s non-government jobs; it has 52.9% of *all* jobs, because 87.6% of the county’s government jobs are in it — that version is shown as a sensitivity). Where car buyers live: DMV registrations (20.6%). Where households are, weighted by income: the American Community Survey (24.5%). Utilities: the same employer measure, checked against the Albany City School District’s own utility tax, which measures the city’s utility base directly (48.9%).
4.  **Multiply each group’s county sales by the city’s share for its class, and add up.** This gives a raw city base of \$2.88 billion, 31.7% of the county.
5.  **Check the method where the answer is known.** Seventeen New York cities already levy their own sales tax, so their bases are known from their collections. Running the identical procedure on them shows it *overstates* the typical city’s base by 10–20% and misses individual cities by about a third either way. Albany’s raw figure is corrected downward to **\$2.42 billion**, and the scatter across those cities sets the error band.
6.  **Multiply by 0.5%**, adjust for the small wedge between tax on the base and cash actually distributed (φ, effectively zero), and allow for any shopping response to the higher rate (β, taken as none): **≈ \$12.2 million a year**, plausibly \$10–15 million.

**Three terms used throughout.**

- **R** — the city’s share of the county’s taxable sales divided by its share of the county’s population. R = 1 means the city has exactly its per-capita share; R = 2 means sales are twice as concentrated in the city as people are. Albany’s R comes out at 0.85; among the 17 taxing cities it runs from 0.45 to 1.89.
- **φ (phi)** — the gap between the tax due on the published base and the cash a locality actually receives: refunds, vendor filing credits, tax paid on private vehicle sales and on audit that never appears in the “taxable sales” statistic, and timing. Measured from the county’s own figures, it is slightly negative — the county receives about 0.7% *more* than 4% of the published base — so it is carried as observed and does not matter.
- **β (beta)** — the fraction of the base that stays put when the rate inside the city is half a point above the rate outside. Taken as 1.0 (no loss), with a low case shown.

**Data sources.** NYS Tax Department: taxable sales by county and industry; sales tax distributions to every locality; Publications 718/718-A/718-C (rates); Publication 838 (motor-vehicle sourcing); TSB-M-90(6)S (the school-district utility tax). U.S. Census Bureau: 2022 Economic Census; LODES employment; American Community Survey; 2020 Census population, block assignment and ZCTA relationship files. NYS DMV: vehicle registrations. Office of the State Comptroller: county sales-tax sharing arrangements and city rates. All are public; the full list with URLs is in §4 and the references.

## 1. The policy option

The City of Albany levies no general sales tax. Albany County levies 4%, which with the 4% state rate gives an 8% combined rate throughout the county. The county retains 60% of its collections and distributes 40% to its cities and towns in proportion to decennial census population (OSC 2020, Appendix C); the city’s share of that distribution is therefore fixed by its population, not by the sales that occur inside it.

The option costed here is an **add-on**: a 0.5-point city tax layered on the existing 8%, so that the combined rate becomes 8.5% inside the city and stays 8% elsewhere in the county. The county’s rate and its distributions are untouched. The tax would apply to the same base as the county tax — the county does not locally exempt clothing under \$110 (Publication 718-C), so no base adjustment is needed — and would be destination-sourced under the ordinary rules, so that motor-vehicle sales, for example, would be taxed by the purchaser’s residence rather than the dealer’s location.

The alternative structure — **preemption**, where a city imposes a rate and the county’s rate falls by the same amount inside the city — is what seventeen New York cities outside New York City do today. It is costed alongside the add-on in §8, because the comparison is what makes the add-on attractive: a preempting city forfeits its share of the county distribution, and for a city whose taxable sales are not disproportionately concentrated inside its borders that forfeiture exceeds what it collects.

One New York city already has exactly the add-on structure. Publication 718 gives 8⅜% for Westchester County and for its cities of Mount Vernon, New Rochelle and White Plains, but 8⅞% for Yonkers. The decomposition is:

|                             | State | MCTD surcharge | County | City | Combined |
|-----------------------------|------:|---------------:|-------:|-----:|---------:|
| Westchester outside Yonkers |    4% |             ⅜% |     4% |    — |      8⅜% |
| Inside Yonkers              |    4% |             ⅜% |     0% |  4½% |      8⅞% |

The ⅜% Metropolitan Commuter Transportation District surcharge applies throughout Westchester and is *not* what makes Yonkers different. Yonkers fully preempts the county’s 4% — Westchester collects nothing inside the city — and imposes 4½%; the extra half point is the city’s rate exceeding the county’s. That is the only published instance of a 0.5-point intra-county rate differential in the state, and Yonkers appears below both as a calibration city and as a direct analogy.

Two things this memo does not do. It does not address the legal route to authorization: every city rate in Publication 718-A that sits above the standard preemption structure carries a footnote referring to an “additional” or “special” rate enacted by specific state legislation, and an Albany add-on would presumably need the same. And it does not model incidence or economic effects beyond a simple behavioral factor.

## 2. Goals

1.  Estimate the annual revenue from the add-on, with an honest error band.
2.  Estimate the city’s taxable sales base — the quantity that drives everything — with a range, since it is published by no one.
3.  Establish where Albany sits relative to New York cities that already tax, so the estimate can be judged against observed cases rather than only against its own internal logic.
4.  Compare the add-on with what the city receives today from its population-based share of the county tax, and with the conventional alternative of preempting part of the county rate, using the same numbers.
5.  Make every figure reproducible from public data.

## 3. Why the estimate is hard

The revenue identity is trivial:

    Revenue = 0.005 × B_c × (1 − φ) × β

where B_c is the city’s taxable sales and purchases, φ the administrative deduction observed in the county’s own distributions, and β a behavioral factor for the rate differential at the city line. φ and β are minor. **B_c is the whole problem.**

The Department of Taxation and Finance publishes taxable sales by *taxing jurisdiction*. Albany County is one; the City of Albany, having no tax, is not. There is no city row in the data, and no vendor-location or ZIP-level tabulation is published. The base has to be estimated.

The one directly observable piece of the city’s base is a fragment: the Albany City School District has imposed a 3% tax on utilities and telecommunications within the city since 1990 (TSB-M-90(6)S), and its collections are published. Dividing by 0.03 gives the city’s utility-and-telecom base, which turns out to be 48.9% of the county’s — the first and only measured city/county share of any part of the base, and a check on the method used for the rest.

## 4. Data

Every dataset was accessed programmatically, its column list verified against live metadata before use, and the raw pull cached with a SHA-256 hash (`data/raw/MANIFEST.csv`). Column lists and the surprises found are in `docs/data-layouts.md`.

### 4.1 New York State Department of Taxation and Finance

**Taxable Sales and Purchases, quarterly** (Open NY dataset `ny73-2j3u`). DTF’s Office of Tax Policy Analysis compiles, from the roughly 250,000 quarterly and 300,000 annual sales tax returns, the dollar amount of taxable sales *and* taxable purchases (use tax) reported by vendors, by the taxing jurisdiction the sale is sourced to and by the vendor’s 4-digit NAICS industry group. It is published quarterly from sales tax year 2013-14 (a sales tax year runs March–February) and is the source of the county base. Used here: Albany County and the eleven counties of the calibration cities, all 302 industry groups, the three sales tax years 2022-23 through 2024-25 (final for 2023-24, preliminary after). Four things to know. The jurisdictions are the state, the MCTD, New York City and the 57 other counties — **no cities**, which is why the city base must be estimated. The industry is the *vendor’s*, and one government group (NAICS 9261, \$8.5 billion statewide, distributed across counties like population and car ownership) appears to be the tax DMV collects on private vehicle sales rather than government vendor activity (§5.2). The industry codes switch from NAICS 2017 to NAICS 2022 at 2022-23 without restating earlier years, and NAICS 2022 has no separate e-commerce category. And individual county × industry cells are withheld for confidentiality (about 3.6% of Albany’s), so every county total here is a sum of *published* cells. <https://data.ny.gov/Government-Finance/Taxable-Sales-And-Purchases-Quarterly-Data-Beginni/ny73-2j3u/about_data>

**State and Local Sales Tax Distributions, annual** (`5g2s-tnb7`). The cash DTF distributed to each taxing jurisdiction — state, MCTD, New York City, every county, every city with its own tax, every city school district utility tax, and the special local taxes — by state fiscal year (April–March) since FY1995. Used here for: Albany County’s distributions (to measure φ and to reconcile the base); the Albany City School District utility-tax distributions (the one directly measured piece of the city base); and the distributions to the 17 preempting cities and their counties, from which each city’s base is recovered as collections ÷ rate. Twenty-three city rows appear; five (Corning, Fulton, Geneva, Hornell, Sherrill) are cents-to-dollars residuals of repealed taxes and are dropped. Yonkers has two rows that must be summed. <https://data.ny.gov/Government-Finance/State-and-Local-Sales-Tax-Distributions-Beginning-/5g2s-tnb7>

**Publications 718, 718-A and 718-C.** Pub 718 lists the combined state-plus-local rate in every jurisdiction, effective 1 March 2025, including separate lines for each preempting city and for the county “except” that city. Pub 718-A lists the enactment and effective dates of every county and city rate since 1965, with footnotes describing the county’s rate inside each preempting city. Pub 718-C lists the localities that exempt clothing and footwear under \$110 — Albany County is not among them, so the add-on base needs no clothing adjustment. Used for every rate in the analysis; see §5.3 for the one place the publications disagree with each other. <https://www.tax.ny.gov/pdf/publications/sales/pub718.pdf>, <https://www.tax.ny.gov/pdf/publications/sales/pub718a.pdf>, <https://www.tax.ny.gov/pdf/publications/sales/pub718c.pdf>

**Publication 838, *A Guide to Sales Tax for Automobile Dealers*, and Form DTF-802.** The authority for sourcing motor-vehicle sales to the purchaser’s residence (§5.2). <https://www.tax.ny.gov/pdf/publications/sales/pub838.pdf>, <https://www.tax.ny.gov/pdf/current_forms/st/dtf802.pdf>

**TSB-M-90(6)S.** The 1990 technical memorandum announcing the Albany City School District’s 3% tax on gas, electricity, refrigeration, steam and telephone service within the city of Albany. It establishes what the school-district collections measure (utilities *and* telecommunications) and that residential energy is taxed at the school district’s full 3% while the county taxes it at a reduced 1%. <https://tax.ny.gov/pdf/memos/sales/m90_6s.pdf>

### 4.2 U.S. Census Bureau

**2022 Economic Census** (API dataset `ecnbasic`). The quinquennial census of business establishments: number of establishments, receipts, employment and annual payroll, by NAICS industry down to 6 digits, for counties and for *economic places* — incorporated places and minor civil divisions above a size threshold. Receipts are total receipts at the establishment’s location, not taxable sales. Used for the store-based allocator: Albany city’s share of Albany County receipts, industry group by industry group, at the finest NAICS level published for both. Withheld cells are published as zero with a separate flag, which must be read or they masquerade as real zeros. The economic-place code for Albany city is `00101000`. <https://api.census.gov/data/2022/ecnbasic.html>

**LEHD Origin-Destination Employment Statistics (LODES), version 8, Workplace Area Characteristics, New York, 2023.** Jobs counted at the workplace, by census block, from state unemployment-insurance records plus federal employment, with a separate count for public administration (NAICS 92). Aggregated block → place through the LODES crosswalk. Used for the business-purchase and utilities allocators — with public administration removed, because governments are exempt purchasers — and for the total-employment sensitivity. <https://lehd.ces.census.gov/data/>

**American Community Survey, 5-year estimates 2019–2023.** Household counts (B11001), aggregate household income (B19025), population (B01003) and aggregate vehicles available (B25046) for Albany city and Albany County. Used for the residence allocator and as a ZIP-free cross-check on the vehicle allocator. <https://api.census.gov/data/2023/acs/acs5.html>

**2020 Census.** Population by place and county (P.L. 94-171), used for population shares and for the county’s distribution formula; population by census block, the Block Assignment Files (block → place) and the ZCTA-to-block relationship file (block → ZIP-code tabulation area), used together to split each ZIP’s registrations between the city and the rest of the county by the population actually living in each part. <https://api.census.gov/data/2020/dec/pl.html>, <https://www2.census.gov/geo/docs/maps-data/data/baf2020/>, <https://www.census.gov/geographies/reference-files/time-series/geo/relationship-files.html>

### 4.3 Other

**NYS DMV, Vehicle, Snowmobile and Boat Registrations** (Open NY `w4pv-hbkt`). Every active registration in the state — about 12.5 million rows — with the registrant’s county, postal city and ZIP, vehicle class, model year and dates. Accessed only through server-side aggregating queries (counts by county × ZIP × state, vehicles only, model year 2024 and later), never downloaded. The `city` field is the postal city, not the municipality — ZIP 12205 is labelled “ALBANY” but is largely the town of Colonie — which is why registrations are assigned to the city through the block-population weights and never by the city name. 9.7% of Albany County registrations carry out-of-state ZIPs (Fort Lauderdale, Port Newark): leasing and fleet registrants with no in-county residence, dropped from numerator and denominator. <https://data.ny.gov/Transportation/Vehicle-Snowmobile-and-Boat-Registrations/w4pv-hbkt>

**Office of the State Comptroller, *Understanding Local Government Sales Tax in New York State: 2020 Update*.** Figure 2 gives each preempting city’s rate; Appendix C summarizes every county’s sharing arrangement with its municipalities, including Albany County’s (60% retained, 40% distributed to cities and towns by census population). <https://www.osc.ny.gov/files/local-government/publications/pdf/understanding-local-government-sales-tax-in-nys-2020-update.pdf>

**Agrawal (2015); Baker, Johnson and Kueng (2021).** Peer-reviewed evidence on cross-border shopping responses to sales-tax differentials, used to frame β.

### 4.4 At a glance

| Source | Role | Period |
|----|----|----|
| DTF taxable sales by county × NAICS | The county base; the denominator of every share | Sales tax years 2022-23 to 2024-25 (mean); 2025-26 for growth |
| DTF distributions | φ; school-district utility base; the 17 cities’ bases | State FY2023–FY2025 |
| DTF Pubs 718 / 718-A / 718-C, Pub 838, TSB-M-90(6)S; OSC 2020 | Rates, sourcing rules, sharing formulas | Current |
| 2022 Economic Census | Store allocator (receipts by place) | 2022 |
| LODES WAC | Business and utilities allocator (jobs by place) | 2023 |
| ACS 5-year | Residence allocator (income; households); vehicles cross-check | 2019–2023 |
| DMV registrations + 2020 Census blocks/ZCTAs | Motor-vehicle allocator | Registrations current; MY ≥ 2024 |
| 2020 Census PL | Population shares | 2020 |

## 5. Methods

### 5.1 The identity, and φ

φ is the wedge between the tax *due* on the published base and the cash a locality actually *receives*. Things that make cash fall short of 4% × base: refunds, the vendor collection credit for timely filing, and any administrative charge. Things that make cash exceed it: tax collected on private-party vehicle sales at DMV registration and on audit, neither of which appears in any vendor’s reported “taxable sales”; late and amended returns; the withheld cells that reduce the published base; and the one-month offset between the sales tax year and the state fiscal year, which in a growing base adds a little. The county’s own data give the net directly: 4% of the published county base against what the county actually received.

| Fiscal year | County base, \$bn | 4% of base, \$m | Distributions, \$m |    Gap |
|:------------|------------------:|----------------:|-------------------:|-------:|
| 2023        |             8.983 |           359.3 |              368.2 |  2.46% |
| 2024        |             9.034 |           361.4 |              357.3 | -1.13% |
| 2025        |             9.251 |           370.0 |              373.2 |  0.84% |

The gap is under 2.5% in every year (the plan’s tripwire was 10%) and is slightly *negative* on average: **Albany County received about 0.72% more than 4% of the published base** over the three years. The additions in the list above outweigh the subtractions. φ is carried at its observed mean of -0.72%; treating it as exactly zero changes the estimate by \$0.1 M.

### 5.2 Apportionment of the county base

Each of the 302 NAICS groups in the county table is assigned to one of five sourcing classes, and the city’s share of each class is estimated with an allocator matched to how that class of sale is sourced under the tax law. The county base in the table is the mean of sales tax years 2022-23, 2023-24 and 2024-25 (March 2022 – February 2025); the “City share” for the store and delivered classes is the base-weighted average of the group-by-group shares.

| Class | Allocator | Groups | County base, \$m | Share of base | City share a_g | City base, \$m |
|:---|:---|---:|---:|---:|---:|---:|
| store | Establishment receipts (EC) | 45 | 4679.9 | 51.5% | 0.288 | 1346.0 |
| business | Workplace employment (LODES) | 244 | 2365.7 | 26.0% | 0.428 | 1012.1 |
| motor_vehicle | Resident registrations (DMV) | 3 | 1074.9 | 11.8% | 0.206 | 221.9 |
| delivered_split | 50% EC receipts / 50% ACS income | 4 | 642.1 | 7.1% | 0.249 | 159.6 |
| utilities | Workplace employment (LODES) | 6 | 327.1 | 3.6% | 0.428 | 140.0 |
| **Total** |  | 302 | 9089.7 | 100.0% | 0.317 | 2879.6 |

By year, the same shares applied to each year’s county base:

| Sales tax year | County base, \$bn | Raw city base, \$bn | Calibrated city base, \$bn | Used in the three-year mean |
|:---|---:|---:|---:|:---|
| 2022 - 2023 | 8.983 | 2.846 | 2.396 | yes |
| 2023 - 2024 | 9.034 | 2.862 | 2.410 | yes |
| 2024 - 2025 | 9.251 | 2.931 | 2.467 | yes |
| 2025 - 2026 | 9.630 | 3.051 | 2.569 |  |

- **Store-based** (retail other than vehicles, restaurants, hotels, recreation, personal services, repair, rental): the city’s share of Economic Census receipts, group by group, at the finest NAICS level at which both the city and the county publish an unsuppressed value. 72 groups resolved at 4 digits and 55 fell back to 3 digits; none needed the sector level. Sales over the counter are sourced where they occur, so establishment receipts are the right allocator, with the caveat that receipts are gross rather than taxable.
- **Business purchases and use tax** (vendors in wholesale, manufacturing, construction, information, finance, professional and administrative services, health, education, public administration other than 9261, and everything else). What this class contains is the taxable sales of *business-serving* vendors — a contractor’s repair work, a cleaning company’s service, software, equipment sold to a non-reseller — plus use tax on businesses’ own purchases, all sourced to the customer’s location. The allocator therefore has to stand for where the *customers* — the purchasing businesses — are, not for where people work and then go to lunch (that spending is already in the store classes through the receipts of the city’s restaurants and shops). Workplace employment is the proxy, **excluding public administration**: New York State and its agencies, like all governments, are exempt from sales tax on their purchases (Tax Law §1116(a)(1)), so the 87.6% of county government jobs that sit in the city generate no taxable purchasing of their own. Total employment including government is shown as a sensitivity, and §9.1 shows that the 17 calibration cities — where government is a small share of jobs — cannot tell the two apart. Two further caveats: hospitals and universities, largely exempt as well, remain in the count; and part of this class (residential repair services, heating fuel) is bought by households and would follow residence rather than employment. Both bias the raw city share upward, and both are among the reasons the calibration corrects the method downward.
- **Motor vehicles** (NAICS 4411, 4412, and 9261 — see the end of this item). Vehicle sales are taxed by the *buyer’s* residence, not the dealer’s location. DTF’s guide for dealers is explicit: “sales tax is collected at the combined rate in effect in the local jurisdiction where the customer is a resident, regardless of where the vehicle is delivered to the customer” (Publication 838, p. 23), and for leases “in the locality where the lessee resides, not the dealership’s location” (p. 16); Form DTF-802, used at DMV registration, instructs “use the tax rate of the new owner’s place of residence.” Under a city add-on, DMV and dealers would therefore charge 8.5% to city residents wherever they buy, and 8% to Colonie residents buying at a dealer inside the city. The allocator is accordingly the city’s share of the county’s *resident* registrations (model year 2024 and later, as a proxy for recent purchases). DMV publishes the registrant’s ZIP, not municipality, so each ZIP’s registrations are divided between the city and the rest of the county in proportion to the 2020 Census population living in each part of that ZIP, block by block. This matters less than it might seem: 68% of the registrations attributed to the city come from ZIPs lying at least 95% inside the city, and only 30% from split ZIPs (chiefly 12203, Pine Hills / Guilderland). Using land area rather than population to split those ZIPs would give 19.9% instead of 20.6%. A cross-check that uses no ZIPs at all — the ACS’s count of vehicles available to households, which has exact city geography — gives 25.7%; it is a stock of all vehicles rather than a flow of new ones, and new-vehicle buying skews to higher-income suburban households, so the DMV flow share sitting below it is what one would expect. Both are shown in §9. Parts and tires (4413) are ordinary counter sales and stay store-based. One more group belongs here: NAICS 9261, *Administration of Economic Programs*, carries \$139 M of “taxable sales” in Albany County and \$8.5 billion statewide. It is not state agencies selling taxable goods in Albany: Albany County’s share of the statewide figure is 1.6%, exactly its population share, and the county pattern follows car ownership (Suffolk and Westchester high, New York City low). NAICS 9261 is the group that contains motor-vehicle departments, and the figure has the signature of the tax DMV collects at registration on private-party vehicle sales — residence-sourced. It is therefore allocated with the motor-vehicle class. This is an inference from the statewide pattern, not something DTF documents; §13 lists it as a limitation.
- **Delivered goods** (building materials, lawn and garden, furniture, electronics and appliances): split 50/50 between the store allocator and the residence allocator (ACS aggregate household income share), because delivery is destination-sourced.
- **Utilities and telecommunications**: allocated by the same business allocator in the generic method so the identical procedure can run on every calibration city; the directly measured school-district base is used as a check (§10) and as a sensitivity (§9.1).

The allocators span a wide range, and which one applies to which part of the base is what the estimate turns on:

| Allocator | City share of county |
|:---|---:|
| Workplace employment excluding public administration (LODES) — used for business and utilities | 42.8% |
| total employment including public administration | 52.9% |
| public administration alone | 87.6% |
| Economic Census payroll, matched private sectors | 47.9% |
| Economic Census receipts, all matched sectors | 41.2% |
| Economic Census receipts, retail (44-45) | 25.9% |
| Economic Census receipts, store classes as used | 28.3% |
| DMV resident registrations, MY ≥ 2024 — used for motor vehicles | 20.6% |
| ACS vehicles available (stock, no ZIP splitting) | 25.7% |
| ACS aggregate household income — used for the residence half of delivered goods | 24.5% |
| ACS households | 33.0% |
| Measured: school-district utility tax ÷ 0.03 | 48.9% |
| Population, 2020 Census | 31.5% |

The city holds 42.8% of the county’s non-government jobs (and 52.9% of all jobs, since 87.6% of the county’s government jobs are in it), but only 20.6% of its vehicle registrations and 25.9% of its retail receipts — the county’s retail has moved to the Wolf Road corridor in Colonie and to Crossgates in Guilderland. The apportionment is a base-weighted average of these, and lands at 31.7% of the county base before calibration.

### 5.3 Calibration against cities whose base is observed

The apportionment is a construction. The seventeen cities outside New York City that impose their own sales tax are the places where the identical construction can be run and then checked, because a preempting city’s base is recoverable from its published collections: B_c = C_c / r_c, with the rates verified from Publications 718 and 718-A and the preemption structure confirmed by an identity test that holds to within 0.5–2.7% in every county. (The eighteenth such city, Oswego, is excluded: its county’s collections behave as though no preemption occurs while the published combined rate says it does, and the two cannot be reconciled.)

**One unresolved point about rates.** Recovering a city’s base as collections ÷ rate requires the rate the city actually imposes, and for six of the seventeen cities the published sources do not agree on it. Publication 718-A’s percentage column reads 3% for Gloversville, Johnstown, New Rochelle, Norwich, Ogdensburg and Saratoga Springs; the Comptroller’s 2020 table (sourced to DTF) gives 2%, 2%, 2.5%, 1.5%, — and 1.5% respectively; and Publication 718-A’s *own footnotes* — which state the county’s rate inside each city — when subtracted from Publication 718’s combined rate reproduce the Comptroller’s figures, not the column. This is not a claim that Publication 718-A is wrong; it is that its percentage column, if read as the city’s imposed rate, contradicts its own footnotes and two other DTF-sourced documents, and its header warns that its rates “cannot be added to determine the combined … rate.” The rates that three sources agree on are used. Because both readings give the same *combined* rate, collections data cannot settle it; the question should be put to DTF. What it would change is shown in §9.2: the six cities’ bases fall by a third to a half under the 718-A reading, the benchmark median R falls from 1.06 to 0.74 — and **Albany’s calibrated estimate barely moves** (\$12.0 M against \$12.2 M), because the calibration absorbs the shift.

The data behind the calibration — for each city, the county base from the DTF taxable-sales file, the city base inferred from its own collections, and the city base the apportionment predicts — are:

| City | County | City rate % | County base, \$m | City base from collections, \$m | City base from apportionment, \$m | Collections ÷ apportionment | Pop. share | R (observed) |
|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| Gloversville | Fulton | 2.0 | 988 | 231 | 188 | 1.229 | 28.4% | 0.82 |
| Rome | Oneida | 1.5 | 4561 | 666 | 572 | 1.164 | 13.8% | 1.06 |
| Johnstown | Fulton | 2.0 | 988 | 278 | 242 | 1.150 | 15.4% | 1.83 |
| Ithaca | Tompkins | 1.5 | 2028 | 965 | 844 | 1.144 | 30.4% | 1.57 |
| Oneida | Madison | 2.0 | 1183 | 340 | 326 | 1.043 | 15.2% | 1.89 |
| Norwich | Chenango | 1.5 | 864 | 166 | 167 | 0.993 | 14.9% | 1.28 |
| Mount Vernon | Westchester | 2.5 | 28454 | 1182 | 1278 | 0.924 | 7.4% | 0.56 |
| Utica | Oneida | 1.5 | 4561 | 948 | 1039 | 0.912 | 28.1% | 0.74 |
| Saratoga Springs | Saratoga | 1.5 | 6187 | 1217 | 1376 | 0.885 | 12.1% | 1.63 |
| White Plains | Westchester | 2.5 | 28454 | 2286 | 2662 | 0.859 | 5.9% | 1.35 |
| New Rochelle | Westchester | 2.5 | 28454 | 1677 | 2038 | 0.823 | 7.9% | 0.74 |
| Olean | Cattaraugus | 1.5 | 1442 | 355 | 482 | 0.735 | 18.1% | 1.36 |
| Auburn | Cayuga | 2.0 | 1481 | 556 | 805 | 0.691 | 35.2% | 1.07 |
| Yonkers | Westchester | 4.5 | 28454 | 2717 | 4214 | 0.645 | 21.1% | 0.45 |
| Glens Falls | Warren | 1.5 | 2584 | 327 | 510 | 0.641 | 22.6% | 0.56 |
| Ogdensburg | St. Lawrence | 1.5 | 2063 | 135 | 259 | 0.522 | 9.3% | 0.71 |
| Salamanca | Cattaraugus | 1.5 | 1442 | 57 | 196 | 0.293 | 7.7% | 0.52 |

The county base is the mean of sales tax years 2022-23 to 2024-25; collections are the mean of state fiscal years 2023–2025. A ratio below 1 means the apportionment over-predicts that city. The regression below is fitted to the logs of the two city-base columns.

Regressing the log of the observed base on the log of the predicted base, with standard errors clustered by county:

| Specification | n | Slope β | se(β) | σ (logs) | R² | Albany base, \$bn | Revenue, \$m |
|:---|---:|---:|---:|---:|---:|---:|---:|
| All 17 cities (used) | 17 | 1.019 | 0.116 | 0.370 | 0.886 | 2.42 | 12.2 |
| Excluding Westchester (4 cities) | 13 | 1.102 | 0.196 | 0.419 | 0.790 | 2.87 | 14.5 |
| Excluding Yonkers | 16 | 1.066 | 0.135 | 0.374 | 0.872 | 2.66 | 13.4 |
| Excluding Salamanca | 16 | 0.928 | 0.063 | 0.249 | 0.932 | 2.27 | 11.4 |
| Excluding Salamanca and Ogdensburg | 15 | 0.881 | 0.033 | 0.192 | 0.954 | 2.21 | 11.1 |

The slope is indistinguishable from 1 — the method scales correctly across cities of very different size. But the residual spread, σ = 0.370 in logs, exceeds the 0.25 threshold set in the plan: **on the cities where the answer is known, the method is routinely off by a third**. The band is widened to match rather than narrowed by dropping observations.

The one large residual with a verifiable structural cause is Salamanca, over-predicted by a factor of three. The 2020 Block Assignment Files place 100% of its population on AIANNH area 0080, the Seneca Nation’s Allegany Territory, where much retail is outside the state tax base but inside the Economic Census. Dropping it cuts σ to 0.249. It is kept in the headline fit anyway, because excluding an observation after seeing that it is inconvenient is how error bands are made to look better than the method deserves; the variant is reported for the reader.

The calibration pulls Albany’s raw prediction of \$2.88 B down to \$2.42 B (a 16% reduction), because the method over-predicts the observed base for most calibration cities — the geometric-mean observed/predicted ratio is 0.818. The plausible mechanism is that Economic Census receipts are gross rather than taxable and that employment over-attributes taxable purchasing to office-heavy cities relative to counties with manufacturing and construction. Both would apply to Albany, so the correction is taken.

### 5.4 β

The add-on makes the rate 8.5% inside the city against 8.0% outside — a 0.46% change in the tax-inclusive price at the city line. Vehicles are unaffected (residence sourcing). Business purchases, utilities and most services do not move. Only the store classes, 59% of the base, are mobile at all, and only near the boundary. β = 1.0 is carried as central; the literature on cross-border shopping (Agrawal 2015; Baker, Johnson and Kueng 2021) establishes that responses exist and are concentrated near rate discontinuities, but neither paper estimates a 0.5-point intra-county differential, so the low cases in §9 are illustrative rather than transported.

## 6. Results

### 6.1 The city’s taxable base

| Measure | Value |
|----|----|
| County base B_k, mean of sales tax years 2022-23 to 2024-25 | \$9.09 B |
| Raw apportionment | \$2.88 B (31.7% of county) |
| **Calibrated central estimate** | **\$2.42 B (26.7% of county)** |
| 68% band | \$1.67–3.51 B |
| 90% band | \$1.32–4.46 B |
| Same share applied to the latest year (2025 - 2026, \$9.63 B) | \$2.57 B |
| Implied R = (city share) ÷ (population share) | 0.85 |

### 6.2 Revenue

| Measure                                | \$ million / year |
|----------------------------------------|-------------------|
| **Central estimate, 2022–2025 levels** | **12.2**          |
| Central estimate at 2025 - 2026 levels | 12.9              |
| 68% band                               | 8.4 – 17.7        |
| 90% band                               | 6.6 – 22.5        |
| With β = 0.97                          | 11.8              |

The county base grew 2.3% a year over 2022-23 to 2025-26 (4.1% in the latest year alone). For a tax starting in 2027 or later the estimate should be read as a share — 26.7% of whatever the county base then is — rather than as a fixed dollar figure.

### 6.3 Where Albany sits among cities that tax

Seventeen preempting cities have an observed R — the city’s share of its county’s taxable sales divided by its share of the county’s population, so that R = 1 means exactly a per-capita share (see the Overview) — ranging from 0.45 (Yonkers) to 1.89 (Oneida), median 1.06. Albany’s calibrated R of 0.85 sits just below the median, next to Gloversville, New Rochelle, Utica. That is the expected shape: a city whose retail has suburbanised (retail R only 0.82) but which holds 42.8% of the county’s private-sector jobs.

The two Albany quantities that can be observed directly bracket the answer: the retail-receipts share (25.9%) below, the measured utility share (48.9%) above, with the estimate at 26.7% in between.

## 7. A reasonable range, and how it relates to the statistical band

Two different ranges are reported and they should not be confused.

The **statistical band** (68%: \$8.4–17.7 M; 90%: \$6.6–22.5 M) comes from the calibration’s residual spread. It treats Albany as no easier to predict than any of the seventeen calibration cities — including Salamanca on tribal land, Ogdensburg on the Canadian border, and Glens Falls sharing a county with Lake George tourism. It is the honest statement of how well the method performs where it can be checked.

The **reasonable planning range of \$10–15 million** (base \$2.0–3.0 billion) is a judgment, and rests on three observations:

1.  Every calibration variant in §5.3 lands between \$11.1 M and \$14.5 M, and the choice of business allocator — the one modelling decision that matters — spans \$12.2–13.4 M (§9.1).
2.  Every alternative *method* in the next section that has no identifiable directional bias lands between roughly \$11 M and \$15 M; the methods outside that span each have a stated reason to be biased.
3.  Albany’s allocators resolve at fine NAICS detail, its Economic Census coverage is near-complete, and its one measurable component (utilities) lies between the two employment allocators. These are the conditions under which the method should do better than its average performance, though nothing in the data proves it.

If a single figure is needed for budgeting, **\$12 million** is the prudent choice at current activity levels: at the central estimate, inside every calibration variant, and above the residence-only floor.

## 8. Alternative methodologies

The apportionment was chosen because it is the only approach that (a) respects how the tax law actually sources each type of sale and (b) can be tested against cities whose answer is known. But it is worth seeing what simpler and different methods give, because their spread is itself information.

| Method | City share | Base, \$bn | Revenue, \$m | Direction of bias |
|:---|---:|---:|---:|:---|
| A. Population share × county base | 31.5% | 2.86 | 14.4 | Ignores structure entirely; a coincidence that it lands near the centre |
| B. ACS aggregate household income share | 24.5% | 2.23 | 11.2 | Low: treats business purchases and commuter/visitor spending as if sourced to residence |
| C. ACS household share | 33.0% | 3.00 | 15.1 | Low, for the same reason; Albany households are small |
| D. Economic Census retail receipts share (44-45) | 25.9% | 2.36 | 11.9 | Low: retail only, ignores services and business purchases which are more city-concentrated |
| E. Economic Census receipts share, all matched sectors | 41.2% | 3.75 | 18.9 | High: origin-based receipts; treats consumer retail as concentrated as offices and hospitals |
| F. Economic Census payroll share, matched sectors | 47.9% | 4.36 | 21.9 | High: payroll concentrates in high-wage office and health employment; omits public administration |
| G. Workplace employment share, excluding public administration (LODES) | 42.8% | 3.89 | 19.6 | High: treats the entire base, including retail and vehicles, as if bought where private employers are |
| G’. Workplace employment share, total (LODES) | 52.9% | 4.81 | 24.2 | Higher still: adds government jobs, whose employers are exempt purchasers |
| H. Measured utility-tax share applied to whole base | 48.9% | 4.45 | 22.4 | High: utilities are the most city-concentrated component of any base |
| I. Route B transfer: median R of 17 cities × population share | 33.3% | 3.02 | 15.2 | Assumes Albany is a typical preempting city; the 17 span a fourfold range |
| J. Per-capita base of 17 cities × Albany population (median) | 23.0% | 2.09 | 10.5 | Low: the 17 are mostly small cities with far less commercial and government activity per resident |
| K. Yonkers analogy: its 0.5-point add-on yield per capita × Albany population |  |  | 6.4 | Low: Yonkers has the lowest R of any taxing city (0.45); its per-capita base is not Albany’s |
| K’. Yonkers analogy, adjusted for Albany’s R relative to Yonkers’ |  |  | 11.9 | Circular — uses this memo’s R — but shows the Yonkers add-on scales consistently |
| L. NAICS apportionment, uncalibrated | 31.7% | 2.88 | 14.5 | High relative to observed cities: over-predicts the typical calibration city by 10–20% |
| M. NAICS apportionment, calibrated (this memo’s central) | 26.7% | 2.42 | 12.2 | — |

Reading the table:

- The **residence-side** methods (B, C, D, J) cluster at \$11–15 M; the **workplace-side** methods (E, F, G, G’, H) cluster at \$19–24 M. Each side is right about part of the base and wrong about the rest. The apportionment is the base-weighted combination, and it lands between them — which is the strongest simple argument that it is doing what it should.
- The **Route B transfer** (I) — assume Albany is a typical taxing city — gives \$15.2 M, but “typical” spans a factor of four across the seventeen cities, so this is a weak anchor.
- The **Yonkers analogy** (K) is the only method that uses the yield of an actual 0.5-point add-on. Yonkers’ special rate is 1.5% (1% plus the 0.5% add-on), so a third of its special-tax collections, \$13.6 M for 2.116e+05 people, is what 0.5 points raises there: \$64 per resident, or \$6.4 M scaled to Albany’s population. That is low because Yonkers is the least commercially concentrated taxing city in the state (R = 0.45); adjusting for Albany’s higher R gives \$11.9 M. The adjustment is circular, but the consistency is reassuring in one respect: a city-boundary 0.5-point differential has been administered by DTF for years.
- The **uncalibrated apportionment** (L) is \$14.5 M. The calibration’s downward correction is the single largest methodological choice in the memo after the allocator assignments themselves, and it is worth 16%.

Methods not implemented, and why:

- **A DTF special tabulation.** The Office of Tax Policy Analysis holds return-level data with vendor location and could tabulate taxable sales inside the city limits directly, as it does for counties considering rate changes. This would replace everything above with a measurement. **It is the single most valuable next step** and the city should request it; the school-district utility tax already gives DTF a precedent for separately accounting for sales within the city of Albany.
- **A demand-side (consumer expenditure) build-up** — resident income × taxable-spending propensity, plus commuter and visitor inflows. Data-hungry, and the inflow term is exactly the unobserved quantity; it would not be independent of the assumptions already made.
- **A retail gravity or catchment model.** Would refine the store allocator but not the business allocator, which is where the uncertainty is.
- **Commercial assessed value share** from the city and county assessment rolls as an alternative business allocator. Feasible and cheap; not pulled here. It would be a useful third opinion alongside employment and payroll.

## 9. Sensitivity analysis

### 9.1 Modelling choices inside the apportionment

Each row changes one choice, re-runs the whole apportionment, and re-applies the calibration.

| Variant | Raw base, \$bn | Calibrated base, \$bn | Revenue, \$m | vs central |
|:---|---:|---:|---:|---:|
| Central | 2.880 | 2.424 | 12.2 | 0.0% |
| Business allocator: total employment, including public administration | 3.152 | 2.658 | 13.4 | 9.6% |
| Business allocator: Economic Census payroll | 3.018 | 2.543 | 12.8 | 4.9% |
| Delivered goods: 0% to residence | 2.882 | 2.426 | 12.2 | 0.1% |
| Delivered goods: 100% to residence | 2.878 | 2.423 | 12.2 | -0.1% |
| Residence allocator: households instead of income | 2.907 | 2.447 | 12.3 | 1.0% |
| E-commerce: 15% of prone groups to residence | 2.874 | 2.420 | 12.2 | -0.2% |
| E-commerce: 30% of prone groups to residence | 2.869 | 2.416 | 12.2 | -0.4% |
| NAICS 4413 (parts, tires) sourced to residence | 2.878 | 2.423 | 12.2 | -0.1% |
| Motor-vehicle allocator: ACS vehicles available instead of DMV registrations | 2.934 | 2.471 | 12.4 | 1.9% |

Only one choice matters: **whether government jobs belong in the allocator for business purchases.** Counting them raises revenue by 10%; the Economic Census payroll alternative (private-sector wages, no government) sits between. The rows above apply the central calibration to each variant’s raw prediction; the proper test re-runs the calibration cities under the same allocator and refits. Doing so:

| Allocator | Albany city share | Slope β | σ (logs) | R² | Raw base, \$bn | Calibrated base, \$bn | Revenue, \$m | 68% band, \$m |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| Employment excluding public administration (used) | 0.428 | 1.019 | 0.370 | 0.886 | 2.88 | 2.42 | 12.2 | 8.4 – 17.7 |
| Total employment, including public administration | 0.529 | 1.019 | 0.361 | 0.892 | 3.15 | 2.65 | 13.4 | 9.3 – 19.2 |
| Economic Census payroll (private sector) | 0.479 | 1.074 | 0.393 | 0.872 | 3.02 | 2.59 | 13.0 | 8.8 – 19.3 |

The fits are indistinguishable. Public administration is only 4–13% of county jobs in the seventeen calibration cities, so their predicted bases barely move when it is removed, and the calibration has no power to say which allocator is right. Albany is out of sample on exactly this dimension — public administration is 23% of county jobs and 88% of those jobs are inside the city — so the choice rests on the conceptual argument, which is clear: government purchases are exempt, and government jobs generate taxable activity only through what their occupants spend, which the store classes already count. The exempt-employer version is used. Using the directly measured school-district share for the utilities class instead of the allocator gives \$12.3 M.

Everything else is immaterial. The delivered-goods split, flagged in the plan as a key assumption, moves the answer by under 0.1%; the e-commerce assignment, which the disappearance of NAICS 454 made unresolvable, moves it by under 1%. Both are immaterial for the same reason: the Economic Census store share and the ACS income share for those groups are within a point of each other, so it barely matters which is used.

### 9.2 Calibration sample and the rate question

**If Publication 718-A’s percentage column is the true rate** for the six cities discussed in §5.3, their recovered bases fall (by a third for the 2%→3% cities, by half for the 1.5%→3% ones). Re-running the calibration on that reading:

| Reading | Benchmark median R | Slope β | σ (logs) | Albany base, \$bn | Revenue, \$m | 68% band, \$m |
|:---|---:|---:|---:|---:|---:|---:|
| Rates agreed by Pub 718-A footnotes, Pub 718 and OSC (used) | 1.06 | 1.019 | 0.370 | 2.42 | 12.2 | 8.4 – 17.7 |
| Pub 718-A percentage column | 0.74 | 1.130 | 0.424 | 2.39 | 12.0 | 7.9 – 18.4 |

The benchmark picture changes a lot; Albany’s estimate does not. Under the alternative reading the method over-predicts the small cities by more, the fitted slope steepens, and the two fits cross near Albany’s size. The band widens.

From §5.3, on the calibration sample: the calibrated central ranges from \$11.1 M (excluding Salamanca and Ogdensburg, the two cities with identifiable structural reasons to be mis-predicted) to \$14.5 M (excluding the four Westchester cities). A slope-fixed-at-one calibration using the geometric mean ratio gives \$11.9 M; using the median ratio gives \$12.8 M.

### 9.3 Behavioural response and administrative deduction

| Assumption                                  | Revenue, \$m |
|:--------------------------------------------|-------------:|
| β = 1.00 (central)                          |         12.2 |
| β = 0.97, whole base                        |         11.8 |
| β = 0.97, store classes only                |         12.0 |
| β = 0.90, whole base (aggressive)           |         11.0 |
| β = 0.90, store classes only                |         11.5 |
| φ = -0.72% observed (central)               |         12.2 |
| φ = 0                                       |         12.1 |
| φ = +2% (an explicit administrative charge) |         11.9 |

Neither factor moves the estimate by more than about 10% even under aggressive assumptions, and both are dwarfed by the base uncertainty.

### 9.4 Base year and growth

| Base | County base, \$bn | City base at 26.7%, \$bn | Revenue, \$m |
|----|---:|---:|---:|
| 2022 - 2023 | 8.983 | 2.40 | 12.1 |
| 2023 - 2024 | 9.034 | 2.41 | 12.1 |
| 2024 - 2025 | 9.251 | 2.47 | 12.4 |
| 2025 - 2026 | 9.630 | 2.57 | 12.9 |
| Three-year mean used (2022-23 to 2024-25) | 9.090 | 2.42 | 12.2 |

## 10. Validations

| \# | Check | Result |
|----|----|----|
| 1 | 4% × county base against county distributions, each year | Gap -1.1% to 2.5%; passes |
| 2 | Economic Census: sum of Albany County places against county total, retail | Places cover 99.2%; residual 0.8% |
| 3 | Utilities: allocator against the directly measured school-district base | Allocator 42.8% vs measured 48.9%; total employment 52.9%. The measured taxable utility base is more city-concentrated than private employment; using it directly changes revenue by \$0.1 M |
| 4 | Motor vehicles: DMV resident share against ACS income share | 20.6% vs 24.5%; DMV lower, consistent with lower urban vehicle ownership |
| 5 | Calibration | Slope 1.019 (se 0.116); σ 0.370, above the 0.25 threshold — band widened, not suppressed |
| 6 | Preemption identity across the 11 calibration counties | (C_k + Σ p_i B_i) ÷ (r_k B_k) between 0.995 and 1.027 |
| 7 | Albany’s implied R against the 17 observed cities | 0.85 within 0.45–1.89, near the median 1.06 |

Validation 3 is the only place an allocator can be tested against a direct observation of an Albany city base. The measured share sits between the two employment allocators, closer to the private-sector one, which is some comfort about the business class — the largest and least certain part of the estimate — without being proof.

## 11. The preemption comparison

Albany County distributes 40% of its collections to cities and towns by census population (OSC 2020, Appendix C). Albany’s status-quo receipt is therefore 0.40 × 31.5% × county collections. Three-year means:

| Option | \$ million / year |
|----|---:|
| Status quo: 0.40 × population share × county collections of \$366.2 M | 46.2 |
| Preempt 1.5 points: 0.015 × B_c | 36.4 |
| **Add on 0.5 points (this memo)** | **12.2** |

Preemption at the standard 1.5 points would *lose* about \$9.8 M a year against the existing distribution. The reason is structural: preemption pays only if the city’s share of the county base exceeds its population share by a factor of 0.40 × 4 ÷ 1.5 = 1.067, and Albany’s R is 0.85. A city has to be a genuine retail concentrator for preemption to work, and Albany — with its county’s retail on Wolf Road and at Crossgates — is not one. The add-on sidesteps the trade-off entirely because it leaves the distribution untouched, which is the whole case for it over the conventional structure.

## 12. Timing and first-year cash

Local rate changes take effect on 1 March, 1 June, 1 September or 1 December, with 90 days’ notice (Tax Law §1210(d), §1211), and transitional rules apply to straddling contracts (Tax Bulletin ST-895). Distributions lag liability by one to two months, with the first two months of each quarter paid as estimates.

On a calendar fiscal year with an average 1.5-month cash lag, a **1 March** start yields roughly 8.6 M of cash in the first year (10 months’ liability, about 8.5 months’ cash) and the full amount from the second. A **1 December** start yields essentially nothing in the first calendar year. If revenue in a particular budget year is the objective, the start date matters as much as most of the modelling choices in §9.

## 13. Limitations

In rough order of importance:

1.  **The treatment of Albany’s exempt public sector.** Government is 23% of the county’s jobs and 88% of those are in the city; government purchases are exempt, so those jobs are excluded from the business allocator, but the only check available — the seventeen calibration cities — has too little government employment to confirm or refute the choice. Including them adds about \$1.2 M. Hospitals and universities, also largely exempt, remain in the count. A DTF tabulation would resolve it.
2.  **The method misses by a third on cities where it can be checked.** Albany may be an easier case — large, fine NAICS detail, near-complete Economic Census coverage — but nothing proves it.
3.  **The calibration sample is small (17) and selected**: mostly small retail-centre cities, with Utica, Rome and the Westchester cities the closest structural analogues to Albany. The fit is reported with and without Westchester.
4.  **Economic Census receipts are gross, not taxable, and are 2022 values applied to 2022-23 to 2024-25 bases.** The allocators are shares, so level drift matters little; the assumption is that a NAICS group’s taxable fraction is similar inside and outside the city.
5.  **Remote sales are not published by delivery jurisdiction**, and NAICS 2022 makes e-commerce unidentifiable in the DTF data. Shown to be immaterial for Albany, but it is an assumption.
6.  **The utility-tax measurement is not clean.** Residential energy is taxed by the county at 1% and by the school district at 3%, so numerator and denominator cover slightly different mixes.
7.  **The imposed rate of six calibration cities is ambiguous in the published sources** (§5.3). The reading supported by three sources is used; the alternative reading widens the band but leaves Albany’s central estimate essentially unchanged (§9.2). Ogdensburg, which re-imposed its tax in 2022 and is absent from the Comptroller’s 2020 table, is the least certain of the six.
8.  **Cell suppression** removes 3–10% of county × NAICS cells; county bases are sums of published cells. The reconciliation bounds the effect at a few percent.
9.  **NAICS 9261 is classified as residence-sourced vehicle tax on the strength of its statewide distribution**, not on documentation. If it is instead business activity sourced where it is reported, it belongs with the business class and the estimate rises by about \$0.1 M.

## 14. Recommendations

1.  **Plan on \$11–17 million a year, with \$12–13 million as the budget figure**, at current activity levels, rising with the county base at 2–4% a year. Do not present the estimate without its band.
2.  **Ask DTF’s Office of Tax Policy Analysis for a direct tabulation** of taxable sales within the city limits. It would replace this estimate with a measurement and would specifically resolve the state-purchasing question. The school-district utility tax gives DTF an existing precedent for separately accounting for sales within the city of Albany.
3.  **Prefer the add-on to preemption.** With Albany’s R below the 1.067 break-even, preemption loses about \$6 million a year relative to the existing distribution; the add-on has no such cost.
4.  **If a start date is discretionary, choose 1 March** for a calendar-year budget; a December start defers essentially all cash to the following year.
5.  If more precision is wanted without DTF’s help, the cheapest improvement is a **taxable commercial assessed-value allocator** from the assessment rolls — which would leave out state-owned and other exempt property automatically — as a third opinion on the business share.

## References

Agrawal, D. R. (2015). The tax gradient: Spatial aspects of fiscal competition. *American Economic Journal: Economic Policy, 7*(2), 1–29. <https://www.aeaweb.org/articles?id=10.1257/pol.20120360>

Baker, S. R., Johnson, S., & Kueng, L. (2021). Shopping for lower sales tax rates. *American Economic Journal: Macroeconomics, 13*(3), 209–250. <https://www.aeaweb.org/articles?id=10.1257/mac.20190026>

New York State Department of Taxation and Finance. (2026). *Taxable sales and purchases quarterly data: Beginning sales tax year 2013–2014* \[Data set\]. <https://data.ny.gov/Government-Finance/Taxable-Sales-And-Purchases-Quarterly-Data-Beginni/ny73-2j3u/about_data>

New York State Department of Taxation and Finance. (2025). *State and local sales tax distributions: Beginning fiscal years ended March 31, 1995* \[Data set\]. <https://data.ny.gov/Government-Finance/State-and-Local-Sales-Tax-Distributions-Beginning-/5g2s-tnb7>

New York State Department of Taxation and Finance. (2025). *Publication 718: New York State sales and use tax rates by jurisdiction*. <https://www.tax.ny.gov/pdf/publications/sales/pub718.pdf>

New York State Department of Taxation and Finance. (2025). *Publication 718-A: Enactment and effective dates of sales and use tax rates*. <https://www.tax.ny.gov/pdf/publications/sales/pub718a.pdf>

New York State Department of Taxation and Finance. (2025). *Publication 718-C: Sales and use tax rates on clothing and footwear*. <https://www.tax.ny.gov/pdf/publications/sales/pub718c.pdf>

New York State Department of Taxation and Finance. (1990). *TSB-M-90(6)S: The Albany City School District imposes a 3% sales and use tax on utilities and utility services*. <https://tax.ny.gov/pdf/memos/sales/m90_6s.pdf>

New York State Department of Taxation and Finance. (2014). *Tax Bulletin ST-895: Transitional provisions for sales tax rate changes*. <https://www.tax.ny.gov/pubs_and_bulls/tg_bulletins/st/transitional_provisions.htm>

New York State Department of Motor Vehicles. (2026). *Vehicle, snowmobile, and boat registrations* \[Data set\]. <https://data.ny.gov/Transportation/Vehicle-Snowmobile-and-Boat-Registrations/w4pv-hbkt>

N.Y. Tax Law §§ 1210, 1211, 1214, 1223, 1224.

Office of the New York State Comptroller. (2020). *Understanding local government sales tax in New York State: 2020 update*. <https://www.osc.ny.gov/files/local-government/publications/pdf/understanding-local-government-sales-tax-in-nys-2020-update.pdf>

U.S. Census Bureau. (2021). *2020 Census redistricting data (P.L. 94-171)* \[API dataset\]. <https://api.census.gov/data/2020/dec/pl.html>

U.S. Census Bureau. (2021). *2020 Census block assignment files*. <https://www2.census.gov/geo/docs/maps-data/data/baf2020/>

U.S. Census Bureau. (2024). *American Community Survey 5-year estimates, 2023* \[API dataset\]. <https://api.census.gov/data/2023/acs/acs5.html>

U.S. Census Bureau. (2025). *Economic Census 2022: Summary statistics for the U.S., states, and selected geographies* \[API dataset `ecnbasic`\]. <https://api.census.gov/data/2022/ecnbasic.html>

U.S. Census Bureau. (n.d.). *2020 relationship files: ZCTA to place, ZCTA to block*. <https://www.census.gov/geographies/reference-files/time-series/geo/relationship-files.html>

U.S. Census Bureau, Longitudinal Employer-Household Dynamics. (2025). *LODES version 8: Workplace Area Characteristics, New York, 2023*. <https://lehd.ces.census.gov/data/>
