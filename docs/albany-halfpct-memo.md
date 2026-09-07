# A 0.5% City of Albany add-on sales tax: policy option, method, data, and findings

2026-09-07

- [Summary](#summary)
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

*Generated 07 September 2026 from `analysis/memo.qmd`. Every number below is computed at render time from the cached source pulls in `data/raw/` (provenance in `data/raw/MANIFEST.csv`); the two crosswalk tables in `data/crosswalk/` are the only hand-entered inputs and each row cites its source. The full technical reports with figures are `_output/analysis/city-halfpct-revenue.html` and `_output/analysis/route-b.html`.*

## Summary

|  |  |
|----|----|
| **Policy option** | A 0.5 percentage-point City of Albany sales and use tax, added on top of the existing 8% (4% state, 4% county), on the same base the county taxes, destination-sourced, with no preemption of the county tax and no change to county distributions. |
| **Central estimate** | **\$13.5 million a year** at 2022–2025 activity levels; about **\$14.3 million** at the latest full year (2025 - 2026) |
| **City taxable base** | **\$2.68 billion**, 29.5% of the county’s \$9.09 billion, against a 31.5% population share |
| **Reasonable planning range** | **\$11–17 million** (base \$2.2–3.3 billion) — see §7 for how this differs from the statistical band |
| **Statistical band** | 68%: \$9.4–19.3 M; 90%: \$7.5–24.3 M |
| **Largest uncertainty** | State-government purchasing inside the city; the estimate moves 9% if public administration is dropped from the business allocator |
| **Preemption comparison** | Preempting 1.5 points instead would yield \$40.2 M against \$46.2 M from the existing county distribution — it loses about \$6.0 M a year |

## 1. The policy option

The City of Albany levies no general sales tax. Albany County levies 4%, which with the 4% state rate gives an 8% combined rate throughout the county. The county retains 60% of its collections and distributes 40% to its cities and towns in proportion to decennial census population (OSC 2020, Appendix C); the city’s share of that distribution is therefore fixed by its population, not by the sales that occur inside it.

The option costed here is an **add-on**: a 0.5-point city tax layered on the existing 8%, so that the combined rate becomes 8.5% inside the city and stays 8% elsewhere in the county. The county’s rate and its distributions are untouched. The tax would apply to the same base as the county tax — the county does not locally exempt clothing under \$110 (Publication 718-C), so no base adjustment is needed — and would be destination-sourced under the ordinary rules, so that motor-vehicle sales, for example, would be taxed by the purchaser’s residence rather than the dealer’s location.

The alternative structure — **preemption**, where a city imposes a rate and the county’s rate falls by the same amount inside the city — is what seventeen New York cities outside New York City do today. It is costed alongside the add-on in §8, because the comparison is what makes the add-on attractive: a preempting city forfeits its share of the county distribution, and for a city whose taxable sales are not disproportionately concentrated inside its borders that forfeiture exceeds what it collects.

One New York city already has exactly the add-on structure. Yonkers takes the full 4% Westchester rate and imposes 4.5%, so its combined rate is 8⅞% against 8⅜% in the rest of the county (Publication 718). It is the only published instance of a 0.5-point intra-county differential in the state and appears below both as a calibration city and as a direct analogy.

Two things this memo does not do. It does not address the legal route to authorization: every city rate in Publication 718-A that sits above the standard preemption structure carries a footnote referring to an “additional” or “special” rate enacted by specific state legislation, and an Albany add-on would presumably need the same. And it does not model incidence or economic effects beyond a simple behavioral factor.

## 2. Goals

1.  Estimate the annual revenue from the add-on, with an honest error band.
2.  Estimate the city’s taxable sales base — the quantity that drives everything — with a range, since it is published by no one.
3.  Establish where Albany sits relative to New York cities that already tax, so the estimate can be judged against observed cases rather than only against its own internal logic.
4.  Document the preemption comparison with the same numbers.
5.  Make every figure reproducible from public data.

## 3. Why the estimate is hard

The revenue identity is trivial:

    Revenue = 0.005 × B_c × (1 − φ) × β

where B_c is the city’s taxable sales and purchases, φ the administrative deduction observed in the county’s own distributions, and β a behavioral factor for the rate differential at the city line. φ and β are minor. **B_c is the whole problem.**

The Department of Taxation and Finance publishes taxable sales by *taxing jurisdiction*. Albany County is one; the City of Albany, having no tax, is not. There is no city row in the data, and no vendor-location or ZIP-level tabulation is published. The base has to be estimated.

The one directly observable piece of the city’s base is a fragment: the Albany City School District has imposed a 3% tax on utilities and telecommunications within the city since 1990 (TSB-M-90(6)S), and its collections are published. Dividing by 0.03 gives the city’s utility-and-telecom base, which turns out to be 48.9% of the county’s — the first and only measured city/county share of any part of the base, and a check on the method used for the rest.

## 4. Data

| Source | Used for | What was verified, and what surprised |
|----|----|----|
| DTF *Taxable Sales and Purchases* (Socrata `ny73-2j3u`) | County base by 4-digit NAICS group, sales tax years 2022-23 to 2025-26 | 60 jurisdictions — state, MCTD, NYC, 57 counties — and **no city rows**. NAICS vintage switches from 2017 to 2022 at 2022-23 without restatement, so **NAICS 454 (nonstore retail / e-commerce) does not exist in the analysis window**. About 3.6% of Albany’s county × NAICS cells are withheld; the reconciliation below bounds their effect. |
| DTF *State and Local Sales Tax Distributions* (`5g2s-tnb7`) | County collections (for φ and reconciliation); school-district utility tax; collections of the 17 preempting cities and their counties | 23 city rows, not 18 — five are trace residuals from repealed taxes and are dropped. Yonkers has two rows (regular 3% and special 1.5%) that must be summed. |
| DTF Publications 718, 718-A, 718-C; OSC 2020 report | Rates; preemption structure; clothing exemption; county distribution formulas | **Publication 718-A’s percentage column is not the imposed city rate** for six cities; its own footnotes, Publication 718’s combined rates and OSC’s Figure 2 agree with each other against it. Albany County does not exempt clothing. Albany County’s 40% distribution on census population verified. |
| 2022 Economic Census (`ecnbasic`) | Store-based allocator: receipts by NAICS at *economic place* level for Albany city and all other places, and for counties | Economic-place codes are 8 digits (Albany = `00101000`); the bare place FIPS returns an empty response. **Suppression is encoded as 0 plus a flag**, not as missing — the flag variables must be pulled or withheld cells read as genuine zeros. Places cover 99.2% of county retail receipts. |
| LEHD LODES WAC 2023 + crosswalk | Business-purchase allocator: workplace employment by place, with public administration retained | `lehdr` cannot aggregate to place; block-to-place done by hand through the crosswalk’s `stplc`. 2023 available, not just 2022. |
| ACS 5-year 2023 (B19025, B11001, B01003) | Residence allocator: aggregate household income (central), households (sensitivity); population check | Income share 24.5% vs household share 33.0% vs population 31.5%. |
| NYS DMV registrations (`w4pv-hbkt`), aggregated server-side | Motor-vehicle allocator: resident registrations, model year ≥ 2024, by county and ZIP | 12.5 million rows; never downloaded whole. `county` is upper case. `city` is the **postal** city — ZIP 12205 is labelled “ALBANY” but is largely Colonie. 9.7% of Albany County registrations carry out-of-state ZIPs (Fort Lauderdale, Port Newark): leasing and fleet registrants. |
| 2020 Census: PL block populations, Block Assignment Files, ZCTA-to-block relationship file | Exact ZIP → place population weights | The ZCTA-to-place file has land area only; ZCTA 12203 is 40% of Albany city by area but **62% by population**. Weights built from 58,120 blocks in 13 counties; the 1 GB national ZCTA-block file was stream-filtered, not downloaded. |
| 2020 Census PL (place, county) | Population shares for the R ratio and the distribution formula | Albany city 9.922e+04, county 3.148e+05. |
| Agrawal (2015); Baker, Johnson & Kueng (2021) | Behavioral factor β | The plan’s Agrawal DOI and title were both wrong; corrected record is 10.1257/pol.20120360. Both resolve. |

Every dataset’s column list and the surprises above are recorded in `docs/data-layouts.md`. The DMV file in particular was accessed only through aggregating queries.

## 5. Methods

### 5.1 The identity, and φ

The county’s own data give φ directly: 4% of the published county base against what the county actually received.

| Fiscal year | County base, \$bn | 4% of base, \$m | Distributions, \$m |    Gap |
|:------------|------------------:|----------------:|-------------------:|-------:|
| 2023        |             8.983 |           359.3 |              368.2 |  2.46% |
| 2024        |             9.034 |           361.4 |              357.3 | -1.13% |
| 2025        |             9.251 |           370.0 |              373.2 |  0.84% |

The gap is under 2.5% in every year (the plan’s tripwire was 10%) and is slightly *negative* on average: the county received a little more than 4% of the published base, reflecting the one-month offset between the sales tax year (March–February) and the state fiscal year (April–March), late and amended returns, and use tax not captured in “taxable sales”. φ is carried at its observed mean of -0.72% — effectively zero.

### 5.2 Apportionment of the county base

Each of the 302 NAICS groups in the county table is assigned to one of five sourcing classes, and the city’s share of each class is estimated with an allocator matched to how that class of sale is sourced under the tax law.

| Class | Allocator | Groups | County base, \$m | Share of base | City share a_g | City base, \$m |
|:---|:---|---:|---:|---:|---:|---:|
| store | Establishment receipts (EC) | 45 | 4679.9 | 51.5% | 0.288 | 1346.0 |
| business | Workplace employment (LODES) | 245 | 2504.6 | 27.6% | 0.529 | 1324.8 |
| motor_vehicle | Resident registrations (DMV) | 2 | 936.0 | 10.3% | 0.206 | 193.3 |
| delivered_split | 50% EC receipts / 50% ACS income | 4 | 642.1 | 7.1% | 0.249 | 159.6 |
| utilities | Workplace employment (LODES) | 6 | 327.1 | 3.6% | 0.529 | 173.0 |

- **Store-based** (retail other than vehicles, restaurants, hotels, recreation, personal services, repair, rental): the city’s share of Economic Census receipts, group by group, at the finest NAICS level at which both the city and the county publish an unsuppressed value. 72 groups resolved at 4 digits and 55 fell back to 3 digits; none needed the sector level. Sales over the counter are sourced where they occur, so establishment receipts are the right allocator, with the caveat that receipts are gross rather than taxable.
- **Business purchases and use tax** (wholesale, manufacturing, construction, information, finance, professional and administrative services, health, education, public administration, and everything else): the city’s share of county workplace employment. State government is the largest concentrated taxable purchaser in the county and is invisible to the Economic Census, which is why employment rather than payroll or receipts is the central allocator, and why public administration is kept in.
- **Motor vehicles** (NAICS 4411, 4412): Tax Law §1214 sources vehicles requiring registration to the purchaser’s residence, so the allocator is the city’s share of the county’s resident registrations, model year 2024 and later, assigned from ZIP to place by exact block-population weights. Parts and tires (4413) are ordinary counter sales and stay store-based.
- **Delivered goods** (building materials, lawn and garden, furniture, electronics and appliances): split 50/50 between the store allocator and the residence allocator (ACS aggregate household income share), because delivery is destination-sourced.
- **Utilities and telecommunications**: allocated by workplace employment in the generic method so the same procedure can run on every calibration city; the directly measured school-district base is used as a check (§10).

The allocators span a wide range, and which one applies to which part of the base is what the estimate turns on:

| Allocator                                       | City share of county |
|:------------------------------------------------|---------------------:|
| Workplace employment (LODES)                    |                52.9% |
| of which: public administration                 |                87.6% |
| employment excluding public administration      |                42.8% |
| Economic Census payroll, matched sectors        |                47.9% |
| Economic Census receipts, all matched sectors   |                41.2% |
| Economic Census receipts, retail (44-45)        |                25.9% |
| Economic Census receipts, store classes as used |                28.3% |
| DMV resident registrations, MY ≥ 2024           |                20.6% |
| ACS aggregate household income                  |                24.5% |
| ACS households                                  |                33.0% |
| Measured: school-district utility tax ÷ 0.03    |                48.9% |
| Population, 2020 Census                         |                31.5% |

The city holds 52.9% of the county’s jobs and 87.6% of its public-administration jobs, but only 20.6% of its vehicle registrations and 25.9% of its retail receipts — the county’s retail has moved to the Wolf Road corridor in Colonie and to Crossgates in Guilderland. The apportionment is a base-weighted average of these, and lands at 35.2% of the county base before calibration.

### 5.3 Calibration against cities whose base is observed

The apportionment is a construction. The seventeen cities outside New York City that impose their own sales tax are the places where the identical construction can be run and then checked, because a preempting city’s base is recoverable from its published collections: B_c = C_c / r_c, with the rates verified from Publications 718 and 718-A and the preemption structure confirmed by an identity test that holds to within 0.5–2.7% in every county. (The eighteenth such city, Oswego, is excluded: its county’s collections behave as though no preemption occurs while the published combined rate says it does, and the two cannot be reconciled.)

Running the same apportionment on those cities and regressing the log of the observed base on the log of the predicted base, with standard errors clustered by county:

| Specification | n | Slope β | se(β) | σ (logs) | R² | Albany base, \$bn | Revenue, \$m |
|:---|---:|---:|---:|---:|---:|---:|---:|
| All 17 cities (used) | 17 | 1.023 | 0.114 | 0.358 | 0.894 | 2.68 | 13.5 |
| Excluding Westchester (4 cities) | 13 | 1.119 | 0.193 | 0.401 | 0.807 | 3.29 | 16.6 |
| Excluding Yonkers | 16 | 1.072 | 0.132 | 0.360 | 0.881 | 2.97 | 14.9 |
| Excluding Salamanca | 16 | 0.933 | 0.063 | 0.240 | 0.937 | 2.48 | 12.5 |
| Excluding Salamanca and Ogdensburg | 15 | 0.887 | 0.035 | 0.185 | 0.958 | 2.41 | 12.1 |

The slope is indistinguishable from 1 — the method scales correctly across cities of very different size. But the residual spread, σ = 0.358 in logs, exceeds the 0.25 threshold set in the plan: **on the cities where the answer is known, the method is routinely off by a third**. The band is widened to match rather than narrowed by dropping observations.

The one large residual with a verifiable structural cause is Salamanca, over-predicted by a factor of three. The 2020 Block Assignment Files place 100% of its population on AIANNH area 0080, the Seneca Nation’s Allegany Territory, where much retail is outside the state tax base but inside the Economic Census. Dropping it cuts σ to 0.240. It is kept in the headline fit anyway, because excluding an observation after seeing that it is inconvenient is how error bands are made to look better than the method deserves; the variant is reported for the reader.

The calibration pulls Albany’s raw prediction of \$3.20 B down to \$2.68 B (a 16% reduction), because the method over-predicts the observed base for most calibration cities — the geometric-mean observed/predicted ratio is 0.807. The plausible mechanism is that Economic Census receipts are gross rather than taxable and that employment over-attributes taxable purchasing to office-heavy cities relative to counties with manufacturing and construction. Both would apply to Albany, so the correction is taken.

### 5.4 β

The add-on makes the rate 8.5% inside the city against 8.0% outside — a 0.46% change in the tax-inclusive price at the city line. Vehicles are unaffected (residence sourcing). Business purchases, utilities and most services do not move. Only the store classes, 59% of the base, are mobile at all, and only near the boundary. β = 1.0 is carried as central; the literature on cross-border shopping (Agrawal 2015; Baker, Johnson and Kueng 2021) establishes that responses exist and are concentrated near rate discontinuities, but neither paper estimates a 0.5-point intra-county differential, so the low cases in §9 are illustrative rather than transported.

## 6. Results

### 6.1 The city’s taxable base

| Measure | Value |
|----|----|
| County base B_k, mean of sales tax years 2022-23 to 2024-25 | \$9.09 B |
| Raw apportionment | \$3.20 B (35.2% of county) |
| **Calibrated central estimate** | **\$2.68 B (29.5% of county)** |
| 68% band | \$1.87–3.83 B |
| 90% band | \$1.49–4.83 B |
| Same share applied to the latest year (2025 - 2026, \$9.63 B) | \$2.84 B |
| Implied R = (city share) ÷ (population share) | 0.94 |

### 6.2 Revenue

| Measure                                | \$ million / year |
|----------------------------------------|-------------------|
| **Central estimate, 2022–2025 levels** | **13.5**          |
| Central estimate at 2025 - 2026 levels | 14.3              |
| 68% band                               | 9.4 – 19.3        |
| 90% band                               | 7.5 – 24.3        |
| With β = 0.97                          | 13.1              |

The county base grew 2.3% a year over 2022-23 to 2025-26 (4.1% in the latest year alone). For a tax starting in 2027 or later the estimate should be read as a share — 29.5% of whatever the county base then is — rather than as a fixed dollar figure.

### 6.3 Where Albany sits among cities that tax

Seventeen preempting cities have an observed R — city share of the county base relative to population share — ranging from 0.45 (Yonkers) to 1.89 (Oneida), median 1.06. Albany’s calibrated R of 0.94 sits just below the median, next to Gloversville, Rome, Auburn. That is the expected shape: a city whose retail has suburbanised (retail R only 0.82) but which contains the state capital and over half the county’s jobs.

The two Albany quantities that can be observed directly bracket the answer: the retail-receipts share (25.9%) below, the measured utility share (48.9%) above, with the estimate at 29.5% in between.

## 7. A reasonable range, and how it relates to the statistical band

Two different ranges are reported and they should not be confused.

The **statistical band** (68%: \$9.4–19.3 M; 90%: \$7.5–24.3 M) comes from the calibration’s residual spread. It treats Albany as no easier to predict than any of the seventeen calibration cities — including Salamanca on tribal land, Ogdensburg on the Canadian border, and Glens Falls sharing a county with Lake George tourism. It is the honest statement of how well the method performs where it can be checked.

The **reasonable planning range of \$11–17 million** (base \$2.2–3.3 billion) is a judgment, and rests on three observations:

1.  Every calibration variant in §5.3 lands between \$12.1 M and \$16.6 M.
2.  Every alternative *method* in the next section that has no identifiable directional bias lands between roughly \$11 M and \$16 M; the methods outside that span each have a stated reason to be biased.
3.  Albany’s allocators resolve at fine NAICS detail, its Economic Census coverage is near-complete, and its one measurable component (utilities) validates the business allocator within 8%. These are the conditions under which the method should do better than its average performance, though nothing in the data proves it.

If a single figure is needed for budgeting, **\$12–13 million** is the prudent choice at current activity levels: near the central estimate, inside every calibration variant, and above the residence-only floor.

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
| G. Workplace employment share (LODES) | 52.9% | 4.81 | 24.2 | High: treats the entire base, including retail and vehicles, as if consumed where people work |
| H. Measured utility-tax share applied to whole base | 48.9% | 4.45 | 22.4 | High: utilities are the most city-concentrated component of any base |
| I. Route B transfer: median R of 17 cities × population share | 33.3% | 3.02 | 15.2 | Assumes Albany is a typical preempting city; the 17 span a fourfold range |
| J. Per-capita base of 17 cities × Albany population (median) | 23.0% | 2.09 | 10.5 | Low: the 17 are mostly small cities with far less commercial and government activity per resident |
| K. Yonkers analogy: its 0.5-point add-on yield per capita × Albany population |  |  | 6.4 | Low: Yonkers has the lowest R of any taxing city (0.45); its per-capita base is not Albany’s |
| K’. Yonkers analogy, adjusted for Albany’s R relative to Yonkers’ |  |  | 13.1 | Circular — uses this memo’s R — but shows the Yonkers add-on scales consistently |
| L. NAICS apportionment, uncalibrated | 35.2% | 3.20 | 16.1 | High relative to observed cities: over-predicts the typical calibration city by 10–20% |
| M. NAICS apportionment, calibrated (this memo’s central) | 29.5% | 2.68 | 13.5 | — |

Reading the table:

- The **residence-side** methods (B, C, D, J) cluster at \$11–15 M; the **workplace-side** methods (E, F, G, H) cluster at \$19–24 M. Each side is right about part of the base and wrong about the rest. The apportionment is the base-weighted combination, and it lands between them — which is the strongest simple argument that it is doing what it should.
- The **Route B transfer** (I) — assume Albany is a typical taxing city — gives \$15.2 M, but “typical” spans a factor of four across the seventeen cities, so this is a weak anchor.
- The **Yonkers analogy** (K) is the only method that uses the yield of an actual 0.5-point add-on. Yonkers’ special rate is 1.5% (1% plus the 0.5% add-on), so a third of its special-tax collections, \$13.6 M for 2.116e+05 people, is what 0.5 points raises there: \$64 per resident, or \$6.4 M scaled to Albany’s population. That is low because Yonkers is the least commercially concentrated taxing city in the state (R = 0.45); adjusting for Albany’s higher R gives \$13.1 M. The adjustment is circular, but the consistency is reassuring in one respect: a city-boundary 0.5-point differential has been administered by DTF for years.
- The **uncalibrated apportionment** (L) is \$16.1 M. The calibration’s downward correction is the single largest methodological choice in the memo after the allocator assignments themselves, and it is worth 16%.

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
| Central | 3.197 | 2.678 | 13.5 | 0.0% |
| Business allocator: employment excluding public administration | 2.910 | 2.433 | 12.3 | -9.2% |
| Business allocator: Economic Census payroll | 3.056 | 2.558 | 12.9 | -4.5% |
| Delivered goods: 0% to residence | 3.199 | 2.680 | 13.5 | 0.1% |
| Delivered goods: 100% to residence | 3.195 | 2.677 | 13.5 | -0.1% |
| Residence allocator: households instead of income | 3.224 | 2.702 | 13.6 | 0.9% |
| E-commerce: 15% of prone groups to residence | 3.192 | 2.674 | 13.5 | -0.2% |
| E-commerce: 30% of prone groups to residence | 3.186 | 2.670 | 13.4 | -0.3% |
| NAICS 4413 (parts, tires) sourced to residence | 3.195 | 2.677 | 13.5 | -0.1% |

Only one choice matters. Dropping public administration from the business allocator cuts revenue by 9%; substituting Economic Census payroll, which omits government entirely and weights toward high-wage sectors, cuts it by 4%. **How much taxable purchasing state agencies do inside the city is the real uncertainty in this estimate**, and no public source measures it.

Everything else is immaterial. The delivered-goods split, flagged in the plan as a key assumption, moves the answer by under 0.1%; the e-commerce assignment, which the disappearance of NAICS 454 made unresolvable, moves it by under 1%. Both are immaterial for the same reason: the Economic Census store share and the ACS income share for those groups are within a point of each other, so it barely matters which is used.

### 9.2 Calibration sample

From §5.3: the calibrated central ranges from \$12.1 M (excluding Salamanca and Ogdensburg, the two cities with identifiable structural reasons to be mis-predicted) to \$16.6 M (excluding the four Westchester cities). A slope-fixed-at-one calibration using the geometric mean ratio gives \$13.0 M; using the median ratio gives \$14.1 M.

### 9.3 Behavioural response and administrative deduction

| Assumption                                  | Revenue, \$m |
|:--------------------------------------------|-------------:|
| β = 1.00 (central)                          |         13.5 |
| β = 0.97, whole base                        |         13.1 |
| β = 0.97, store classes only                |         13.3 |
| β = 0.90, whole base (aggressive)           |         12.1 |
| β = 0.90, store classes only                |         12.7 |
| φ = -0.72% observed (central)               |         13.5 |
| φ = 0                                       |         13.4 |
| φ = +2% (an explicit administrative charge) |         13.1 |

Neither factor moves the estimate by more than about 10% even under aggressive assumptions, and both are dwarfed by the base uncertainty.

### 9.4 Base year and growth

| Base | County base, \$bn | City base at 29.5%, \$bn | Revenue, \$m |
|----|---:|---:|---:|
| 2022 - 2023 | 8.983 | 2.65 | 13.3 |
| 2023 - 2024 | 9.034 | 2.66 | 13.4 |
| 2024 - 2025 | 9.251 | 2.73 | 13.7 |
| 2025 - 2026 | 9.630 | 2.84 | 14.3 |
| Three-year mean used (2022-23 to 2024-25) | 9.090 | 2.68 | 13.5 |

## 10. Validations

| \# | Check | Result |
|----|----|----|
| 1 | 4% × county base against county distributions, each year | Gap -1.1% to 2.5%; passes |
| 2 | Economic Census: sum of Albany County places against county total, retail | Places cover 99.2%; residual 0.8% |
| 3 | Utilities: employment allocator against the directly measured school-district base | 52.9% vs 48.9% — within 8% |
| 4 | Motor vehicles: DMV resident share against ACS income share | 20.6% vs 24.5%; DMV lower, consistent with lower urban vehicle ownership |
| 5 | Calibration | Slope 1.023 (se 0.114); σ 0.358, above the 0.25 threshold — band widened, not suppressed |
| 6 | Preemption identity across the 11 calibration counties | (C_k + Σ p_i B_i) ÷ (r_k B_k) between 0.995 and 1.027 |
| 7 | Albany’s implied R against the 17 observed cities | 0.94 within 0.45–1.89, near the median 1.06 |

Validation 3 deserves emphasis. It is the only place an allocator can be tested against a direct observation of an Albany city base, and the employment allocator — the one carrying the largest share of the estimate and the largest uncertainty — passes it.

## 11. The preemption comparison

Albany County distributes 40% of its collections to cities and towns by census population (OSC 2020, Appendix C). Albany’s status-quo receipt is therefore 0.40 × 31.5% × county collections. Three-year means:

| Option | \$ million / year |
|----|---:|
| Status quo: 0.40 × population share × county collections of \$366.2 M | 46.2 |
| Preempt 1.5 points: 0.015 × B_c | 40.2 |
| **Add on 0.5 points (this memo)** | **13.5** |

Preemption at the standard 1.5 points would *lose* about \$6.0 M a year against the existing distribution. The reason is structural: preemption pays only if the city’s share of the county base exceeds its population share by a factor of 0.40 × 4 ÷ 1.5 = 1.067, and Albany’s R is 0.94. A city has to be a genuine retail concentrator for preemption to work, and Albany — with its county’s retail on Wolf Road and at Crossgates — is not one. The add-on sidesteps the trade-off entirely because it leaves the distribution untouched, which is the whole case for it over the conventional structure.

## 12. Timing and first-year cash

Local rate changes take effect on 1 March, 1 June, 1 September or 1 December, with 90 days’ notice (Tax Law §1210(d), §1211), and transitional rules apply to straddling contracts (Tax Bulletin ST-895). Distributions lag liability by one to two months, with the first two months of each quarter paid as estimates.

On a calendar fiscal year with an average 1.5-month cash lag, a **1 March** start yields roughly 9.6 M of cash in the first year (10 months’ liability, about 8.5 months’ cash) and the full amount from the second. A **1 December** start yields essentially nothing in the first calendar year. If revenue in a particular budget year is the objective, the start date matters as much as most of the modelling choices in §9.

## 13. Limitations

In rough order of importance:

1.  **State-government purchasing is real, large, concentrated in the city, and unmeasured.** Employment counts jobs, not purchases. This is the dominant uncertainty and is not reducible with public data; a DTF tabulation would resolve it.
2.  **The method misses by a third on cities where it can be checked.** Albany may be an easier case — large, fine NAICS detail, near-complete Economic Census coverage — but nothing proves it.
3.  **The calibration sample is small (17) and selected**: mostly small retail-centre cities, with Utica, Rome and the Westchester cities the closest structural analogues to Albany. The fit is reported with and without Westchester.
4.  **Economic Census receipts are gross, not taxable, and are 2022 values applied to 2022-23 to 2024-25 bases.** The allocators are shares, so level drift matters little; the assumption is that a NAICS group’s taxable fraction is similar inside and outside the city.
5.  **Remote sales are not published by delivery jurisdiction**, and NAICS 2022 makes e-commerce unidentifiable in the DTF data. Shown to be immaterial for Albany, but it is an assumption.
6.  **The utility-tax measurement is not clean.** Residential energy is taxed by the county at 1% and by the school district at 3%, so numerator and denominator cover slightly different mixes.
7.  **Ogdensburg’s rate**, one of seventeen calibration points, rests on Publication 718-A footnote reasoning rather than a published rate table. It does not drive the fit.
8.  **Cell suppression** removes 3–10% of county × NAICS cells; county bases are sums of published cells. The reconciliation bounds the effect at a few percent.

## 14. Recommendations

1.  **Plan on \$11–17 million a year, with \$12–13 million as the budget figure**, at current activity levels, rising with the county base at 2–4% a year. Do not present the estimate without its band.
2.  **Ask DTF’s Office of Tax Policy Analysis for a direct tabulation** of taxable sales within the city limits. It would replace this estimate with a measurement and would specifically resolve the state-purchasing question. The school-district utility tax gives DTF an existing precedent for separately accounting for sales within the city of Albany.
3.  **Prefer the add-on to preemption.** With Albany’s R below the 1.067 break-even, preemption loses about \$6 million a year relative to the existing distribution; the add-on has no such cost.
4.  **If a start date is discretionary, choose 1 March** for a calendar-year budget; a December start defers essentially all cash to the following year.
5.  If more precision is wanted without DTF’s help, the cheapest improvement is a **commercial assessed-value allocator** from the assessment rolls as a third opinion on the business share, followed by a request to the state for **agency purchasing by location** from the Statewide Financial System.

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
