# Meta-notes for a reviewer (human or AI)

Everything a second analyst needs that is **not** already in `CLAUDE.md`,
`README.md`, `docs/data-layouts.md`, or the two analysis documents. This is the
working knowledge that would otherwise live only in the head of whoever built
it: judgment calls and why they went the way they did, things that were tried
and abandoned, claims by how well they are verified, mistakes made and
corrected, and what to attack first.

Written 2026-09-08. If the numbers below disagree with the rendered documents,
the documents are authoritative — they compute at render time.

---

## 1. Read these first, in this order

1. `docs/albany-halfpct-memo.md` — the memo. §5A is the analytical core.
2. `docs/data-layouts.md` — every dataset's verified schema and the ten places
   it differed from what the project plan assumed.
3. `R/04_allocate.R` — the apportionment engine.
4. `R/05_calibrate.R` — Route B reduced form (section A), calibration
   (section B), diagnostics (section C).

Rendered HTML is in `_output/`; the published site is
<https://donboyd5.github.io/albany_sales_tax/>.

---

## 2. The three things most likely to be wrong

Ranked by (probability wrong) × (effect on the answer).

**a. The two excluded calibration cities — and, tangled with them, the functional
form.** On the 15-city sample the log-log fit gives \$11.1 M but a slope fixed
at 1 (geometric-mean ratio) gives \$13.1 M; on all 17 the two forms agree
(\$12.5 M vs \$11.4 M the other way). The log-log slope of 0.88 is carried by
the four Westchester cities. The leave-one-out table in memo §5A shows only
Salamanca and Ogdensburg change σ, which supports the exclusion; the grid in
§9.2 shows the exclusion then makes the functional form matter. Both are
reported; the planning range is the envelope.

**a′ (original).** The two excluded calibration cities. The headline \$11.1 M uses 15 of 17
cities; all 17 gives \$12.5 M with a much wider band (σ 0.19 vs 0.45). Salamanca
and Ogdensburg are dropped for documented reasons (Seneca Nation territory;
brand-new jurisdiction code plus a border-traffic collapse). The reasons are
verified from independent sources and were fixed before the effect on the answer
was known — but this is still the single judgment that moves the number most,
and a reviewer is entitled to reject it. Both fits are carried everywhere.

**b. The rates of five cities.** Gloversville, Johnstown, New Rochelle, Norwich
and Saratoga Springs: Publication 718-A's percentage column says 3, 3, 3, 3, 3;
OSC's Figure 2 says 2.0, 2.0, 2.5, 1.5, 1.5. The city base is collections ÷
rate, so this is a factor of up to 2 per city. Three lines of evidence favour
OSC (its Figure 2 is sourced to DTF; 718-A's own footnotes, subtracted from Pub
718's combined rate, reproduce OSC's numbers; and OSC's rates give a tighter
calibration, SD 0.359 vs 0.429). Saratoga Springs at 1.5% is independently
confirmed by the Saratoga County Treasurer. The other four are **not**
individually confirmed from a city code. Doing so is the highest-value
remaining verification task.

**c. NAICS 9261.** \$139 M of Albany County's base, moved from the business
class to the motor-vehicle class on the inference that its \$8.5 B statewide
total distributes across counties like population and car ownership — the
signature of DMV-collected tax on private vehicle sales. DTF does not document
this. If wrong it is worth about +\$0.1 M, so the stakes are low, but the
inference is mine and unconfirmed.

---

## 3. Corrections already made — do not "rediscover" these as errors

Each of these was wrong at some point in the build and is now fixed. They are
listed so a reviewer does not waste time re-deriving them, and so the *reasons*
survive.

| What was wrong | Why it was wrong | Now |
|---|---|---|
| City rates read off Pub 718-A's percentage column | That column is not the imposed city rate; 718-A's header warns its rates "cannot be added" | OSC + footnote + Pub 718 triangulation |
| Ogdensburg at 1.5% | Inferred by analogy from Pub 718-A footnote `a`; the analogy does not hold | **3.0%** — city code imposes 3% under §1210(a), city preempted the county's base 3%, county keeps only its non-preemptable additional 1% (§1224); matches Pub 718's combined 8% and DTF notice ST-22-1 |
| Business allocator = total employment | Rested on the project plan's premise that "state government is a large taxable purchaser". It is not — governments are exempt under §1116(a)(1) | Employment **excluding** public administration |
| Presenting total employment as an "upper case" | Gave a rejected specification the status of a live alternative | Reported as a specification test only |
| Sensitivity tables applied the all-17 fit to variant predictions while the central used the 15-city fit | Apples-to-oranges; the "Central" row showed a non-zero "vs central" | All variants use the preferred fit |
| Economic Census read without suppression flags | EC publishes withheld cells as `0` plus a companion `_F` flag; without the flag they look like real zeros | `_F` variables pulled and converted to `NA` |
| ZIP→place by land area | Understates a dense core badly (ZCTA 12203 is 40% of Albany city by area, 62% by population) | Exact 2020 block-population weights |
| Agrawal (2015) citation from the project plan | Both the DOI and the title were wrong | `10.1257/pol.20120360`, *The Tax Gradient: Spatial Aspects of Fiscal Competition* |
| Validation 3 said the measured utility share was "closer to the private-sector allocator" | Arithmetic error: 48.9% is 4.0 points from total employment (52.9%) and 6.1 from the allocator used (42.8%) | Corrected, with the defence made explicitly: State utility purchases are exempt, so the measured share is taxable commercial load, not evidence for counting government jobs |
| β = 0.97 labelled "an elasticity of about 0.5 with respect to the tax-inclusive price" | 0.5 is the elasticity to the tax *rate*; to the price (+0.46%) it is ≈ 6.5 | Relabelled; the low case is now described as deliberately aggressive |
| "Off by a third", "wrong by a third in either direction" | Loose, stale after σ changed, and wrong on the upside of a multiplicative band | Computed: +57%/−36% at σ 0.453, +21%/−17% at 0.192 |
| Three different planning ranges and budget figures across the memo; a hardcoded "$6 million" preemption loss | An edit script chained assertions and wrote the file only at the end; when one pattern failed, every earlier substitution in that script was silently lost. Several sections kept stale hand-typed figures for a full commit | Planning range, budget figure and preemption loss are now computed in the setup chunk; edit scripts write incrementally and report each patch |
| Route B report rendered with Ogdensburg at 1.5% after the crosswalk said 3.0% | Quarto's `freeze: auto` reuses a document's cached results when *its own source* is unchanged, even if a data file it reads has changed | `_freeze/` is deleted before every full render (`make render` does this) |

---

## 4. Judgment calls, with the reasoning that is not in the documents

**Why calibrate to collections rather than to the "true" base.** The city will
receive *collections*. If vendors systematically mis-code sales to the county
(§5A, mechanism 1), the observed city base understates the true economic base —
but Albany's collections would be understated the same way. So collections are
the correct calibration target even though they are a biased measure of economic
activity. This is why no attempt is made to "correct" the observed bases upward.

**Why the preemption identity cannot rescue us here.** It reconciles to
0.995–1.027 across eleven counties, which is reassuring about rates and about
the county base covering the whole county. But it is blind to city/county
mis-coding: understate the city and overstate the county by the same amount and
the total still equals `r_k × B_k`. Do not treat the identity as evidence
against mechanism 1.

**Why the calibration is in logs with a multiplicative band.** Base sizes span
three orders of magnitude across the 17 cities (Salamanca \$57 M to Yonkers
\$2.7 B). Errors are proportional, not additive. **Read σ correctly**: because
the band is multiplicative, a one-σ move is `exp(σ)−1` up and `1−exp(−σ)` down,
which are not equal. σ = 0.192 is +21% / −17%; σ = 0.453 is +57% / −36%. Earlier
drafts described this loosely as "off by a third", which was wrong on the upside
and stale after σ changed; the documents now compute both figures.

**Why standard errors are clustered by county.** Fulton, Cattaraugus, Oneida and
Westchester each contribute more than one city, and §5A shows county effects
explain 83% of the residual variance — so within-county observations are very
far from independent. Unclustered SEs would be badly overconfident.

**Yonkers: analog for what, exactly.** Earlier drafts called Yonkers "the exact
policy being estimated for Albany". Wrong in one sense: Yonkers preempts the
county entirely and then adds 1½% by special act; Albany would keep its
distribution share and add 0.5% on the general base, which has no New York
precedent this analysis could find. Right in the other: Yonkers is the only
place in the state where the combined rate steps up 0.5 points at a city line,
so it is the analog for administration and for β. The documents now say which.
The memo's §11 preemption comparison is the substantive answer to "why not use
§1224" — for Albany, preemption loses money.

**Why 4413 (auto parts, tires) is store-based but 4411/4412 are not.** §1214
residence-sourcing applies to vehicles *required to be registered*. Tyres are
counter sales. Worth \$65 M; in the sensitivity table.

**Why utilities are allocated rather than measured in the main path.** The
Albany City School District's utility tax gives a directly measured city
utility base — but only for Albany. The calibration must run the *identical*
procedure on 17 other cities, none of which has such a tax. So utilities are
allocated like business purchases, and the measurement is used as a validation
(they agree within about 12%) and as a sensitivity.

**Why the store allocator weights by the DTF taxable base, not by EC receipts.**
Within a NAICS group the city/county split comes from EC receipts, but groups
are combined using their *taxable* base. This handles composition (a group that
is mostly exempt gets little weight) without needing group-level taxable
fractions.

---

## 4A. Process failure worth knowing about

Several contradictions a reviewer found on 2026-09-08 — three different
planning ranges in one document, a stale "$6 million", a §12 first-year ramp
that was announced in code comments but absent from the text — had one cause.
Text edits were applied by Python scripts that asserted each search string
existed and wrote the file only at the end; when one string failed to match,
the script aborted and every *earlier* substitution in it was lost without any
message. The fix is procedural: patch helpers now write after every
substitution and print which labels landed and which missed. If you find a
number that contradicts the setup chunk, suspect this first.

## 5. Things tried that did not work — do not redo them

- **Predicting the county effect.** County fixed effects explain 83% of the
  residual variance, so a county-level predictor would be worth a lot.
  Regressing the county mean ratio on county taxable base per capita gives the
  expected negative sign but p ≈ 0.6, R² ≈ 0.03 on 11 counties. Also tried and
  weak: business-class share of base, store base per capita, city population
  share, exempt-sector employment concentration, allocator fallback quality
  (all |cor| < 0.27 against log ratio). **The county effect is real and
  currently unpredictable.** This is the main reason the band cannot be
  narrowed further with public data.
- **Quantifying the hospital/university exposure.** *Now done*: LODES CNS15
  (education) and CNS16 (health) are in `lodes_place`; dropping them with
  government gives a business share of 35.6% and a bound of about −\$0.6 M
  (memo §9.1). An earlier draft said this could not be done; it could.
- **Backing out an implied business-class allocator per city.** Solving for the
  `a_bus` that would reconcile each city's observed base gives *negative* values
  for the worst-predicted cities (Salamanca −0.41, Auburn −0.35). Impossible,
  and therefore informative: the over-prediction cannot be located in the
  business class alone; the store allocator is implicated too.
- **ZBP for the ZIP payroll fallback.** The API ends at 2018. Use `cbp` 2023,
  which has a `zip code` geography — but note it is NAICS2017 and ZIP × detailed
  NAICS is heavily suppressed. In the end no fallback beyond EC sector level was
  needed for Albany.
- **`lehdr::grab_lodes(agg_geo = "place")`.** Does not exist in 1.2.0. Block →
  place is done by hand through the crosswalk's `stplc`.
- **Fetching legal aggregators programmatically.** doi.org, findlaw, justia,
  nysenate and ecode360 all return 403 to non-browser clients. They resolve
  fine in a browser. `R/99_check_urls.R` lists them separately rather than
  failing. Statutes are cited by section.

---

## 6. Verification status of the main claims

| Claim | How verified | Confidence |
|---|---|---|
| Albany County rate 4%, no clothing exemption | Pub 718, Pub 718-A, Pub 718-C | Certain |
| DTF county base covers the whole county incl. preempting cities | Preemption identity, 11 counties, 0.995–1.027 | Very high |
| p_c = r_c for all cities but Yonkers | Pub 718 publishes equal combined rates inside and outside | Very high |
| Yonkers has a combined rate 0.5 points above its county's | Pub 718: 8⅞% inside vs 8⅜% outside; MCTD applies county-wide | Certain — but it is an *economic* analog (a differential at a city line), not a legal precedent: the half point sits on top of full preemption. No NY city keeps its county distribution share and levies a general-base add-on. Narrow-base layered city taxes (Niagara Falls, Lockport, Long Beach, Newburgh, Port Jervis, and the ACSD utility tax) do exist without preemption. |
| ACSD tax covers telecom as well as utilities | TSB-M-90(6)S, read in full | Certain |
| Salamanca 100% on tribal territory | 2020 Census Block Assignment Files, AIANNH 0080 | Certain (the *tax* consequence is inference from 20 NYCRR 529.9) |
| Ogdensburg rate 3.0% | City code via ecode360; corroborated by §1224 reasoning and DTF ST-22-1 | High |
| Saratoga Springs rate 1.5% | Saratoga County Treasurer | High |
| Other four disputed rates | OSC Figure 2 + 718-A footnotes + Pub 718 arithmetic | Medium-high |
| Glens Falls under-prediction is Lake George/Queensbury | Warren County Treasurer's own by-town sales tax report | High |
| New jurisdiction codes under-collect at first | Ogdensburg's ramp (3.01→3.45%) vs flat Ithaca; n=1 | Medium |
| 9261 is DMV-collected vehicle tax | Statewide distribution pattern only | Low-medium |
| Albany County distributes 40% on census population | OSC 2020 Appendix C | Certain |
| φ ≈ 0 | Albany County's own base and distributions, 3 years | Certain |

---

## 7. Known weaknesses nobody has fixed

- **Hospitals and universities are exempt purchasers but stay in the business
  allocator.** LODES cannot separate an exempt hospital from a taxable employer
  within a sector. Albany has a lot of both. Biases the city share up; not
  quantified.
- **The calibration cities cannot test the government-jobs question.** Public
  administration is 4–13% of county jobs in all 17; it is 22.6% in Albany
  County with 87.6% of it inside the city. Albany is out of sample on the one
  dimension where the specification choice matters.
- **Economic Census is 2022 applied to 2022-25 bases.** Shares, so level drift
  is second order; composition drift is not addressed.
- **EC receipts are gross, not taxable**, and the taxable fraction is assumed
  similar inside and outside the city within a NAICS group. §5A shows this is
  false for at least Auburn.
- **n = 17 (15 used), and the sample is selected** — mostly small retail-centre
  cities. Utica, Rome and the Westchester cities are the closest structural
  analogues to Albany, and none is a state capital.
- **DMV registrations are a stock of recent model years, not a purchase flow.**
  The ACS vehicles cross-check is a stock too. Neither is a true flow measure.
- **First-year ramp is calibrated on one observation** (Ogdensburg).

---

## 8. What would actually improve the estimate

In order of value per unit of effort.

1. **A DTF special tabulation of taxable sales inside the Albany city limits.**
   The Office of Tax Policy Analysis holds return-level data with jurisdiction
   coding and already maintains separate reporting for the Albany City School
   District utility tax within the city — so the geography exists in their
   systems. This would replace the entire estimate with a measurement and would
   settle the government-purchasing question. Everything else on this list is a
   substitute for not having it.
2. **Confirm the four unverified city rates** from municipal codes (§2b).
3. **Taxable commercial assessed value** by municipality from the county
   assessment rolls, as a third business allocator. It excludes exempt property
   automatically, which is exactly the weakness of the employment allocator.
4. **Ask DTF whether city/county mis-coding is measurable** — e.g. whether they
   see reporting-code corrections concentrated after a new city code is created.
   Would turn §5A mechanism 1 from a hypothesis into a quantity.
5. **More preempting-city years.** The panel is three years; a longer panel
   would let the county effect be estimated as a random effect rather than
   absorbed.

---

## 9. Reproduction gotchas

- `renv::restore()`, then a Census API key in `.Renviron` as `CENSUS_API_KEY`.
- `quarto render` takes several minutes: the memo re-fits the calibration for
  three business allocators, each of which re-apportions all 17 cities.
- If a source script changes, delete `_freeze/` — Quarto's freeze cache will
  otherwise serve stale figures, and every number in the documents is computed
  at render time.
- `make render` renders and refreshes `docs/albany-halfpct-memo.md`;
  `make publish` pushes `_output/` to the `gh-pages` branch. `quarto publish
  gh-pages` does **not** work — this is a `type: default` project, not a
  website project — hence `scripts/publish_gh_pages.sh`.
- The DMV dataset is 12.5 M rows. Every access must be an aggregating SoQL
  query. Do not download it.
- The national ZCTA-to-block relationship file is ~1 GB and is stream-filtered
  to 13 counties inside `R/03`. Do not fetch it whole.
- `data/raw/` is committed (~23 MB of CSVs) so the build is reproducible without
  network access. `MANIFEST.csv` carries source URL, timestamp and SHA-256.

---

## 10. Numbers a reviewer should be able to reproduce

As of 2026-09-08, central specification:

```
County base B_k (3-yr mean, sales tax years 2022-23..2024-25)   $9.09 B
Raw apportionment B_c                                           $2.88 B
Calibrated B_c (15-city fit)                                    $2.21 B
Implied city share / R                                          24.3% / 0.77
Revenue                                                         $11.1 M
68% / 90% band                                                  $9.2-13.5 / $8.1-15.3 M
All-17 alternative                                              $12.5 M, 68% $7.9-19.6 M
Calibration: beta 0.881 (se 0.033), sigma 0.192, R2 0.954, n=15
County FE share of residual variance                            0.831
GM(observed/predicted): all 17 / preferred 15                   0.785 / 0.903
phi (3-yr mean)                                                 -0.72%
Allocators: store 0.288, business 0.428, motor vehicle 0.206,
            measured utilities 0.489, population 0.315
```


## Book conversion (2026-09-09)

The write-up became a Quarto book (`_quarto.yml`, `chapters/`, `appendices/`).
`R/06_results.R` computes everything into `data/processed/results.rds`;
chapters read it through `chapters/_common.R`, so no chapter recomputes
anything and all chapters agree. Freeze is off; `make render` clears `_freeze`.

New in this pass, prompted by the reviewer's doubt about the business class:

- `business_customer_family()` / `business_customer_type()` in `R/04` tag each
  business-class group as mostly business / mixed / household, with a
  rationale per family; the crosswalk CSV carries the tags. Judgment, not data.
- `ec_estab_share()` (business locations) and a `residence` option as business
  allocators; `business_by_customer = TRUE` in `apportion_variant()`.
- `alloc_fits` now covers seven business rules, calibration re-fitted each time.
- Cross-city diagnostic: log(obs/pred) on (private-job share − population
  share) across the 15 preferred cities. No relationship.
- Pub 718-R checked: Albany County does not tax residential energy. Validation
  3's measured share is therefore an upper bound; the old "closer to total
  employment" reading is retracted in the book.

The planning range now excludes the two rules judged implausible (all jobs
including government; residence for the whole class) when forming the
envelope; it is still $8–15 M because the σ-upper-CI band dominates.

## Residential energy in the county row (2026-09-09, second pass)

The reviewer asked whether the DTF county figure is the state-tax base. It is
not: it covers sales subject to state, MCTD, county and NYC tax (DTF's own
description), residential energy sits on Schedule B jurisdiction lines, and a
cross-county comparison keyed to Pub 718-R shows utilities per person roughly
doubling in counties that tax residential energy. Albany County does not, so
its row excludes it. See docs/data-layouts.md §12a and the apportionment
chapter's "Does the county figure include residential energy?" section.
