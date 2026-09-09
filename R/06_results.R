## R/06_results.R ----------------------------------------------------------
## Computes every quantity the book reports and saves them to
## data/processed/results.rds. Each chapter of the book reads that file, so
## all chapters see identical numbers and render in seconds. Re-run this
## script (Rscript R/06_results.R, or `make results`) whenever a raw pull,
## a crosswalk or an R function changes. Nothing here touches the network.
## -------------------------------------------------------------------------

suppressMessages({
  library(here)
  source(here("R", "04_allocate.R"))
})
t0 <- Sys.time()
R <- list()

## Regenerate the NAICS crosswalk so the customer-type columns are current.
cw_naics <- build_naics_crosswalk()

ALB <- list("Albany city, New York", "3601000", "36001", "ALBANY", "ALBANY")
R$ALB <- ALB
R$ANALYSIS_FYS <- ANALYSIS_FYS
R$years_label <- sprintf("%d–%d", min(ANALYSIS_FYS) - 1, max(ANALYSIS_FYS))

## --- population -------------------------------------------------------------
pp  <- read_pop()
R$P_c <- pp$place$P_c[pp$place$place_fips == "3601000"]
R$P_k <- pp$county$P_k[pp$county$county_fips == "36001"]
R$pop <- R$P_c / R$P_k
pop <- R$pop; P_c <- R$P_c

## --- apportionment and calibration -----------------------------------------
appo   <- do.call(apportion_city, ALB)
R$appo <- appo
R$B_k  <- B_k <- sum(appo$B_kg)
R$B_pred <- B_pred <- sum(appo$B_cg, na.rm = TRUE)
calib  <- build_calibration()
fit    <- fit_calibration(calib)
est    <- apply_calibration(fit, B_pred)
phi_tab <- albany_phi()
phi    <- mean(phi_tab$phi)
rev    <- function(b, beta = 1, ph = phi) 0.005 * b * (1 - ph) * beta
cal_pref <- calib |> filter(!city %in% names(CALIB_EXCLUDE))
fit_pref <- fit_calibration(cal_pref)
est_pref <- apply_calibration(fit_pref, B_pred)
R$calib <- calib; R$fit <- fit[c("alpha","beta","se_beta","sigma","r2","n")]; R$est <- est
R$cal_pref <- cal_pref; R$fit_pref <- fit_pref[c("alpha","beta","se_beta","sigma","r2","n")]
R$est_pref <- est_pref
R$phi <- phi; R$phi_tab <- phi_tab
R$CALIB_EXCLUDE <- CALIB_EXCLUDE
R$cty_fe   <- county_effect_share(calib)
R$gm_all   <- exp(mean(log(calib$ratio))); R$gm_pref <- exp(mean(log(cal_pref$ratio)))
R$diag     <- calibration_diagnostics()
R$REV      <- REV <- rev(est_pref$B_c_central)
R$REV_all  <- rev(est$B_c_central)
R$s_ci     <- sigma_ci(fit_pref)
R$loo      <- leave_one_out(calib, B_pred)
R$grid     <- grid <- calibration_grid(calib, B_pred)
R$ramp     <- new_code_ramp()
R$s_cal    <- s_cal <- est_pref$B_c_central / B_k
R$R_cal    <- s_cal / pop
R$route_b  <- route_b <- summarise_route_b(build_route_b())
R$identity <- check_identity(build_route_b())
R$oswego   <- oswego_evidence()
R$suppression <- suppression_report()

## county base by year
by_year <- read_county_base() |> filter(jurisdiction == "ALBANY", fy <= 2026) |>
  group_by(sales_tax_year, fy) |> summarise(B = sum(B, na.rm = TRUE), .groups = "drop") |>
  mutate(growth = B / lag(B) - 1)
R$by_year <- by_year
R$B_latest <- by_year$B[by_year$fy == 2026]
R$latest_label <- by_year$sales_tax_year[by_year$fy == 2026]
R$cagr <- (by_year$B[by_year$fy == 2026] / by_year$B[by_year$fy == 2023])^(1/3) - 1

## --- allocator shares --------------------------------------------------------
R$a_work <- a_work <- work_share("3601000", "36001")
R$a_pub  <- a_pub  <- pubadmin_share("3601000", "36001")
R$a_wxp  <- a_wxp  <- work_share_ex_pubadmin("3601000", "36001")
R$a_exx  <- a_exx  <- work_share_ex_exempt("3601000", "36001")
R$a_pay  <- a_pay  <- ec_payroll_share("Albany city, New York", "001")
R$a_estab <- a_estab <- ec_estab_share("Albany city, New York", "001")
R$a_inc  <- a_inc  <- resid_share("01000", "001", "agginc")
R$a_hh   <- a_hh   <- resid_share("01000", "001", "hh")
R$a_mv   <- a_mv   <- mv_share("3601000", "ALBANY")
R$a_util <- a_util <- albany_measured_utility_share()
R$a_veh  <- a_veh  <- acs_vehicle_share("01000", "001")
is_sector <- function(x) grepl("^[0-9]{2}$|^[0-9]{2}-[0-9]{2}$", x)
ec_p <- ec_place_sector |> filter(NAME == "Albany city, New York", is_sector(NAICS2022), !is.na(RCPTOT)) |> select(NAICS2022, p = RCPTOT)
ec_k <- ec_county_sector |> filter(county == "001", is_sector(NAICS2022), !is.na(RCPTOT)) |> select(NAICS2022, k = RCPTOT)
ec_j <- inner_join(ec_p, ec_k, by = "NAICS2022")
R$a_ecall <- a_ecall <- sum(ec_j$p) / sum(ec_j$k)
R$a_ecret <- a_ecret <- ec_j$p[ec_j$NAICS2022 == "44-45"] / ec_j$k[ec_j$NAICS2022 == "44-45"]
R$a_store <- a_store <- with(appo[appo$sourcing_class %in% c("store", "delivered_split"), ], sum(a_store_used * B_kg) / sum(B_kg))
lodes_alb <- lodes_place |> filter(cty == "36001")
R$pub_pct <- with(lodes_alb, sum(CNS20) / sum(C000))
R$store_share_of_base <- store_share_of_base <- sum(appo$B_kg[appo$sourcing_class %in% c("store", "delivered_split")]) / B_k
R$oos_share <- with(dmv_by_zip |> filter(county == "ALBANY"), sum(n[state != "NY"]) / sum(n))

## motor vehicles: ZIP-split decomposition and area alternative
wz <- zip_place_weights |> filter(place_fips == "3601000") |> select(zcta, w)
dz <- dmv_by_zip |> filter(county == "ALBANY", state == "NY") |>
  left_join(wz, by = c("zip" = "zcta")) |> mutate(w = ifelse(is.na(w), 0, w),
  kind = case_when(w >= 0.95 ~ "in", w <= 0.05 ~ "out", TRUE ~ "split"))
R$mv_from_unambiguous <- sum(dz$n[dz$kind == "in"] * dz$w[dz$kind == "in"]) / sum(dz$n * dz$w)
R$mv_from_split       <- sum(dz$n[dz$kind == "split"] * dz$w[dz$kind == "split"]) / sum(dz$n * dz$w)
za <- zcta_place |> filter(GEOID_PLACE_20 == "3601000") |>
  transmute(zcta = GEOID_ZCTA5_20, wa = as.numeric(AREALAND_PART) / as.numeric(AREALAND_ZCTA5_20))
da <- dmv_by_zip |> filter(county == "ALBANY", state == "NY") |> left_join(za, by = c("zip" = "zcta")) |> mutate(wa = ifelse(is.na(wa), 0, wa))
R$a_mv_area <- sum(da$n * da$wa) / sum(da$n)

## --- class summary --------------------------------------------------------------
CLASS_LABEL <- c(store = "Over-the-counter sales", business = "Sales to businesses and other non-store sales",
                 motor_vehicle = "Motor vehicles", delivered_split = "Delivered household goods",
                 utilities = "Utilities and telephone")
CLASS_ALLOC <- c(store = "Where the stores are (Economic Census receipts)",
                 business = "Where private-sector jobs are (LODES, excluding government)",
                 motor_vehicle = "Where car owners live (DMV registrations)",
                 delivered_split = "Half stores, half household income (ACS)",
                 utilities = "Where private-sector jobs are (LODES, excluding government)")
R$CLASS_LABEL <- CLASS_LABEL; R$CLASS_ALLOC <- CLASS_ALLOC
R$cls <- appo |>
  group_by(class = sourcing_class) |>
  summarise(groups = n(), B = sum(B_kg), a = sum(B_cg, na.rm = TRUE) / sum(B_kg),
            B_c = sum(B_cg, na.rm = TRUE), .groups = "drop") |>
  mutate(share = B / B_k, label = CLASS_LABEL[class], allocator = CLASS_ALLOC[class]) |>
  arrange(desc(B))
R$n_store_4digit <- sum(grepl("4-digit", appo$store_method))
R$n_store_3digit <- sum(grepl("3-digit", appo$store_method))

## --- inside the business class ------------------------------------------------------
bus <- appo |> filter(sourcing_class == "business") |>
  mutate(family = business_customer_family(naics_industry_group),
         customer = business_customer_type(naics_industry_group),
         family_label = CUSTOMER_FAMILY_LABEL[family],
         rationale = CUSTOMER_RATIONALE[family])
R$bus <- bus
R$B_bus <- B_bus <- sum(bus$B_kg)
R$bus_family <- bus |> group_by(family, family_label, customer, rationale) |>
  summarise(groups = n(), B = sum(B_kg), .groups = "drop") |>
  mutate(share_of_class = B / B_bus, share_of_base = B / B_k) |> arrange(desc(B))
R$bus_customer <- bus |> group_by(customer) |>
  summarise(groups = n(), B = sum(B_kg), .groups = "drop") |>
  mutate(share_of_class = B / B_bus, share_of_base = B / B_k)
R$bus_top <- bus |> arrange(desc(B_kg)) |>
  transmute(naics_industry_group, description, family_label, customer, B = B_kg,
            share_of_class = B_kg / B_bus) |> head(30)
R$bus_sector2 <- bus |> mutate(s2 = substr(naics_industry_group, 1, 2)) |>
  group_by(s2) |> summarise(B = sum(B_kg), groups = n(), .groups = "drop") |>
  mutate(share_of_class = B / B_bus) |> arrange(desc(B))

## --- what is in the employment allocator ------------------------------------------------
CNS_LABEL <- c(CNS01 = "Agriculture", CNS02 = "Mining", CNS03 = "Utilities", CNS04 = "Construction",
  CNS05 = "Manufacturing", CNS06 = "Wholesale trade", CNS07 = "Retail trade",
  CNS08 = "Transportation and warehousing", CNS09 = "Information", CNS10 = "Finance and insurance",
  CNS11 = "Real estate", CNS12 = "Professional and technical services", CNS13 = "Management of companies",
  CNS14 = "Administrative, support and waste services", CNS15 = "Education", CNS16 = "Health care and social assistance",
  CNS17 = "Arts, entertainment and recreation", CNS18 = "Accommodation and food services",
  CNS19 = "Other services", CNS20 = "Public administration (government)")
pl_names <- read_csv(file.path(PATHS$raw, "census_pl2020_place_ny.csv"), col_types = cols(.default = "c")) |>
  transmute(stplc = paste0("36", place), place_name = NAME)
R$lodes_sector <- lodes_alb |> select(stplc, starts_with("CNS")) |>
  pivot_longer(-stplc, names_to = "cns", values_to = "jobs") |>
  group_by(cns) |> summarise(city = sum(jobs[stplc == "3601000"]), county = sum(jobs), .groups = "drop") |>
  mutate(rest = county - city, share = city / county, label = CNS_LABEL[cns],
         exempt_flag = cns %in% c("CNS20", "CNS15", "CNS16")) |>
  arrange(desc(county))
R$lodes_place_tab <- lodes_alb |> left_join(pl_names, by = "stplc") |>
  mutate(place_name = ifelse(stplc == "9999999", "Not inside any city, village or census-designated place (mostly the towns' unincorporated areas)", sub(", New York$", "", place_name)),
         priv = C000 - CNS20, ex_exempt = C000 - CNS20 - CNS15 - CNS16) |>
  transmute(place_name, total = C000, government = CNS20, private = priv,
            edu_health = CNS15 + CNS16, private_ex_exempt = ex_exempt) |>
  arrange(desc(total)) |>
  mutate(share_total = total / sum(total), share_private = private / sum(private),
         share_private_ex_exempt = private_ex_exempt / sum(private_ex_exempt))
R$city_jobs <- lodes_alb |> filter(stplc == "3601000") |>
  transmute(total = C000, government = CNS20, private = C000 - CNS20, edu = CNS15, health = CNS16)
R$county_jobs <- lodes_alb |> summarise(total = sum(C000), government = sum(CNS20), private = sum(C000 - CNS20),
                                        edu = sum(CNS15), health = sum(CNS16))
## Economic Census: city vs county by sector (receipts, payroll, jobs, establishments)
ecp <- ec_place_sector |> filter(NAME == "Albany city, New York", is_sector(NAICS2022)) |>
  select(NAICS2022, NAICS2022_LABEL, p_r = RCPTOT, p_pay = PAYANN, p_emp = EMP, p_est = ESTAB)
eck <- ec_county_sector |> filter(county == "001", is_sector(NAICS2022)) |>
  select(NAICS2022, k_r = RCPTOT, k_pay = PAYANN, k_emp = EMP, k_est = ESTAB)
R$ec_sector <- inner_join(ecp, eck, by = "NAICS2022") |>
  mutate(sh_r = p_r / k_r, sh_pay = p_pay / k_pay, sh_emp = p_emp / k_emp, sh_est = p_est / k_est) |>
  arrange(desc(k_pay))

## --- cross-city evidence on the employment allocator -----------------------------------
cw_c <- read_crosswalk_cities() |> filter(include)
al <- purrr::map_dfr(seq_len(nrow(cw_c)), function(i) {
  pf <- substr(cw_c$place_fips[i], 1, 7); c5 <- paste0("36", substr(cw_c$county_fips[i], 3, 5))
  c3 <- substr(cw_c$county_fips[i], 3, 5)
  d <- lodes_place |> filter(cty == c5)
  tibble(city = cw_c$city[i], a_work = work_share(pf, c5), a_wxp = work_share_ex_pubadmin(pf, c5),
         a_exx = work_share_ex_exempt(pf, c5), a_inc = resid_share(substr(pf, 3, 7), c3, "agginc"),
         pub_pct = sum(d$CNS20) / sum(d$C000),
         eduhealth_city = sum(d$CNS15[d$stplc == pf] + d$CNS16[d$stplc == pf]) /
                          sum(d$C000[d$stplc == pf] - d$CNS20[d$stplc == pf]))
})
xcity <- calib |> left_join(al, by = "city") |>
  mutate(lr = log(ratio), gap = a_wxp - pop_share, excluded = city %in% names(CALIB_EXCLUDE))
R$xcity <- xcity
x15 <- xcity |> filter(!excluded)
m_gap <- lm(lr ~ gap, x15)
R$xcity_fit <- list(slope = unname(coef(m_gap)[2]), se = summary(m_gap)$coefficients[2, 2],
                    p = summary(m_gap)$coefficients[2, 4], r2 = summary(m_gap)$r.squared, n = nrow(x15))
R$alb_gap <- a_wxp - pop
R$alb_eduhealth <- (R$city_jobs$edu + R$city_jobs$health) / R$city_jobs$private

## --- calibration variants (memo §5.3 / §9.2) ---------------------------------------------------
cal_variant <- function(d, lbl) {
  m <- lm(log_obs ~ log_pred, d); s <- summary(m)$sigma
  ct <- lmtest::coeftest(m, vcov. = sandwich::vcovCL(m, cluster = d$county))
  c0 <- exp(coef(m)[1] + coef(m)[2] * log(B_pred))
  tibble(Specification = lbl, n = nrow(d), beta = unname(coef(m)[2]), se = ct[2, 2], sigma = s,
         R2 = summary(m)$r.squared, B_c = unname(c0), rev = rev(unname(c0)),
         lo68 = rev(c0 * exp(-s)), hi68 = rev(c0 * exp(s)),
         lo90 = rev(c0 * exp(-1.645 * s)), hi90 = rev(c0 * exp(1.645 * s)))
}
R$cv <- cv <- bind_rows(
  cal_variant(calib, "All 17 cities"),
  cal_variant(filter(calib, !westchester), "Excluding Westchester (4 cities)"),
  cal_variant(filter(calib, city != "Yonkers"), "Excluding Yonkers"),
  cal_variant(filter(calib, city != "Salamanca"), "Excluding Salamanca"),
  cal_variant(filter(calib, !city %in% c("Salamanca", "Ogdensburg")), "Excluding Salamanca and Ogdensburg (used)"))
R$gm_ratio <- exp(mean(calib$log_obs - calib$log_pred)); R$med_ratio <- median(calib$ratio)

## --- sensitivity: one knob at a time, central calibration re-applied ----------------------------
variants <- tribble(
  ~Variant, ~args,
  "Central", list(),
  "Business sharing rule: total employment, including government", list(business_allocator = "lodes"),
  "Business sharing rule: Economic Census payroll", list(business_allocator = "ec_payroll"),
  "Business sharing rule: Economic Census business locations", list(business_allocator = "ec_estab"),
  "Business sharing rule: employment excluding government, education and health (exempt-institution bound)", list(business_allocator = "lodes_ex_exempt"),
  "Business class split by customer type (household part by residence)", list(business_by_customer = TRUE),
  "Business sharing rule: household income (residence) for the whole class (floor)", list(business_allocator = "residence"),
  "Delivered goods: 0% to residence", list(delivered_to_residence = 0),
  "Delivered goods: 100% to residence", list(delivered_to_residence = 1),
  "Residence sharing rule: households instead of income", list(resid_var = "hh"),
  "E-commerce: 15% of prone groups to residence", list(ecommerce_frac = 0.15),
  "E-commerce: 30% of prone groups to residence", list(ecommerce_frac = 0.30),
  "NAICS 4413 (parts, tires) sourced to residence", list(mv_include_4413 = TRUE),
  "Motor vehicles: ACS vehicles available instead of DMV registrations", list(mv_allocator = "acs_vehicles"))
R$sens <- sens <- variants |> rowwise() |>
  mutate(B_pred_v = do.call(apportion_variant, c(ALB, args)),
         B_cal_v = apply_calibration(fit_pref, B_pred_v)$B_c_central,
         Rev = rev(B_cal_v)) |> ungroup() |> select(-args)
R$B_util_meas <- B_util_meas <- sum(ifelse(appo$sourcing_class == "utilities", appo$B_kg * a_util, appo$B_cg), na.rm = TRUE)
R$REV_util_meas <- rev(apply_calibration(fit_pref, B_util_meas)$B_c_central)

## --- business sharing rule alternatives with the calibration re-fitted under each -------------------
BUS_ALT <- tribble(
  ~key, ~label, ~args,
  "lodes_ex_pubadmin", "Private-sector jobs, excluding government (used)", list(business_allocator = "lodes_ex_pubadmin"),
  "lodes", "All jobs, including government", list(business_allocator = "lodes"),
  "ec_payroll", "Private-sector payroll (Economic Census)", list(business_allocator = "ec_payroll"),
  "ec_estab", "Private business locations (Economic Census establishments)", list(business_allocator = "ec_estab"),
  "lodes_ex_exempt", "Private jobs excluding government, education and health", list(business_allocator = "lodes_ex_exempt"),
  "by_customer", "Split by customer type: household-facing groups by residence, mixed half and half", list(business_by_customer = TRUE),
  "residence", "Household income (residence) for the whole class", list(business_allocator = "residence"))
alb_share <- c(lodes_ex_pubadmin = a_wxp, lodes = a_work, ec_payroll = a_pay, ec_estab = a_estab,
               lodes_ex_exempt = a_exx, by_customer = NA, residence = a_inc)
R$alloc_fits <- alloc_fits <- purrr::map_dfr(seq_len(nrow(BUS_ALT)), function(i) {
  args <- BUS_ALT$args[[i]]
  cal_v <- do.call(build_calibration_variant, args) |> filter(!city %in% names(CALIB_EXCLUDE))
  f_v <- fit_calibration(cal_v)
  Bp_v <- do.call(apportion_variant, c(ALB, args)); e_v <- apply_calibration(f_v, Bp_v)
  tibble(key = BUS_ALT$key[i], label = BUS_ALT$label[i], albany_share = unname(alb_share[BUS_ALT$key[i]]),
         beta = f_v$beta, sigma = f_v$sigma, r2 = f_v$r2,
         B_pred = Bp_v, B_cal = e_v$B_c_central, rev = rev(e_v$B_c_central),
         lo68 = rev(e_v$lo68), hi68 = rev(e_v$hi68))
})
## the business-class city share implied by the customer-type split
bus_split <- bus |> mutate(a_split = case_when(customer == "household" ~ a_inc,
                                               customer == "mixed" ~ 0.5 * a_wxp + 0.5 * a_inc,
                                               TRUE ~ a_wxp))
R$a_bus_split <- sum(bus_split$a_split * bus_split$B_kg) / sum(bus_split$B_kg)
R$alloc_fits$albany_share[R$alloc_fits$key == "by_customer"] <- R$a_bus_split

## --- alternatives (memo §8) -------------------------------------------------------------------------
R$pc_cities <- pc_cities <- route_b$B_c / route_b$P_c
d3 <- read_distributions() |> filter(fy %in% ANALYSIS_FYS)
R$yonk_special <- yonk_special <- mean(d3$amt[d3$taxing_jurisdiction == "City of Yonkers Special Sales and Use Tax"])
R$yonk_half <- yonk_half <- yonk_special / 3
R$yonk_pop  <- yonk_pop  <- pp$place$P_c[pp$place$place_fips == "3684000"]
R$R_yonk    <- R_yonk    <- route_b$R[route_b$city == "Yonkers"]
R$C_k <- C_k <- mean(d3$amt[d3$taxing_jurisdiction == "Albany County Sales and Use Tax"])
R$status_quo <- status_quo <- 0.40 * pop * C_k
R$PREEMPT_LOSS <- status_quo - 0.015 * est_pref$B_c_central

## --- rate-ambiguity variant -------------------------------------------------------------------
cal_alt <- build_calibration(rate_source = "pub718a_col")
fit_alt <- fit_calibration(cal_alt)
R$fit_alt <- fit_alt[c("alpha","beta","se_beta","sigma","r2","n")]
R$est_alt <- apply_calibration(fit_alt, B_pred)
R$rb_alt  <- summarise_route_b(build_route_b(rate_source = "pub718a_col"))

R$B_9261 <- B_9261 <- appo$B_kg[appo$naics_industry_group == "9261"]
R$rev_9261_as_business <- rev(apply_calibration(fit_pref, B_pred + B_9261 * (a_wxp - a_mv))$B_c_central)

## --- how well does collections / rate recover reported taxable sales? -------------------------
## At the county level both are observed, so the inference used for the 17
## cities can be tested directly. County rates are transcribed from Pub 718
## (data/crosswalk/county_rates_pub718.csv); preempted city amounts are added
## back from the city crosswalk.
rates_k <- read_csv(file.path(PATHS$crosswalk, "county_rates_pub718.csv"), col_types = cols(.default = "c")) |>
  transmute(county, r_k_pub718 = as.numeric(county_rate))
cw_all <- read_crosswalk_cities()
dist_all <- read_distributions()
Bk_all <- read_county_base() |> filter(fy %in% ANALYSIS_FYS, !jurisdiction %in% c("NY STATE", "MCTD", "NY CITY")) |>
  group_by(county = jurisdiction, fy) |> summarise(B_k = sum(B, na.rm = TRUE), .groups = "drop")
Ck_all <- dist_all |> filter(fy %in% ANALYSIS_FYS, grepl("County Sales and Use Tax$", taxing_jurisdiction)) |>
  mutate(county = toupper(sub(" County Sales and Use Tax", "", taxing_jurisdiction)),
         county = ifelse(county == "ST. LAWRENCE", "ST LAWRENCE", county)) |> select(county, fy, C_k = amt)
pre_all <- cw_all |> tidyr::crossing(fy = ANALYSIS_FYS) |> rowwise() |>
  mutate(C_c = sum(dist_all$amt[dist_all$fy == fy & grepl(dist_city_pattern, dist_all$taxing_jurisdiction)]),
         preempted = C_c * p_c / r_c) |> ungroup() |>
  group_by(county = dtf_jurisdiction, fy) |> summarise(preempted = sum(preempted, na.rm = TRUE), n_cities = n(), .groups = "drop")
county_test <- Bk_all |> inner_join(Ck_all, by = c("county", "fy")) |> left_join(pre_all, by = c("county", "fy")) |>
  mutate(preempted = coalesce(preempted, 0), n_cities = coalesce(n_cities, 0L)) |>
  inner_join(rates_k, by = "county") |>
  mutate(inferred = (C_k + preempted) / (r_k_pub718 / 100), ratio = inferred / B_k)
R$county_test <- county_test
R$county_test_by_county <- county_test |> group_by(county, r_k_pub718, n_cities) |>
  summarise(B_k = mean(B_k), inferred = mean(inferred), ratio = mean(ratio), ratio_min = min(ratio), ratio_max = max(ratio),
            swing = max(ratio) - min(ratio), .groups = "drop") |> arrange(ratio)
R$county_test_summary <- list(
  n_county_years = nrow(county_test), n_counties = n_distinct(county_test$county),
  median = median(county_test$ratio), mean = mean(county_test$ratio), sd = sd(county_test$ratio),
  q05 = unname(quantile(county_test$ratio, 0.05)), q95 = unname(quantile(county_test$ratio, 0.95)),
  within5 = mean(abs(county_test$ratio - 1) < 0.05), within10 = mean(abs(county_test$ratio - 1) < 0.10),
  median_swing = median(R$county_test_by_county$swing), max_swing = max(R$county_test_by_county$swing),
  sd_log = sd(log(county_test$ratio)))

## Year-to-year stability of each city's inferred share of its county base.
rb_panel <- build_route_b()
R$city_stability <- rb_panel |> group_by(city, county) |>
  summarise(s_mean = mean(s), s_min = min(s), s_max = max(s), swing = (max(s) - min(s)) / mean(s), .groups = "drop") |>
  left_join(cw_all |> transmute(city, rate_note = note,
                                rate_all_agree = !city %in% c("Gloversville", "Johnstown", "New Rochelle", "Norwich",
                                                              "Ogdensburg", "Saratoga Springs")), by = "city") |>
  arrange(desc(swing))

## Calibration restricted to the cities whose inferred base is best supported:
## rate agreed by every published source (no Pub 718-A conflict), inferred
## share stable across the three years (swing under 10%), and the two
## structural exclusions. Reported alongside the preferred fit.
TRUST_CITIES <- R$city_stability |> filter(rate_all_agree, swing < 0.10, !city %in% names(CALIB_EXCLUDE)) |> pull(city)
R$TRUST_CITIES <- TRUST_CITIES
cal_trust <- calib |> filter(city %in% TRUST_CITIES)
fit_trust <- fit_calibration(cal_trust)
R$fit_trust <- fit_trust[c("alpha", "beta", "se_beta", "sigma", "r2", "n")]
R$est_trust <- apply_calibration(fit_trust, B_pred)
R$REV_trust <- rev(R$est_trust$B_c_central)
R$REV_raw <- rev(B_pred)

## --- does the county row include residential energy? cross-county test ------------------------
## Pub 718-R lists which counties tax residential energy. If the DTF county
## row included residential energy wherever a local tax applies, counties that
## tax it should show a much larger utilities base per person than counties
## that do not; if the row were the state-tax base, no difference.
re_cw <- read_csv(file.path(PATHS$crosswalk, "pub718r_residential_energy.csv"),
                  col_types = cols(.default = col_character(), county_taxes_part1 = col_logical(),
                                   county_taxes_part2 = col_logical(), school_district_or_city_only = col_logical()))
pop_k <- read_csv(file.path(PATHS$raw, "census_pl2020_county_ny.csv"), col_types = cols(.default = "c")) |>
  transmute(county = toupper(sub(" County, New York", "", NAME)), P = as.numeric(P1_001N)) |>
  mutate(county = ifelse(county == "ST. LAWRENCE", "ST LAWRENCE", county))
re_test <- read_county_base() |>
  filter(fy %in% ANALYSIS_FYS, !jurisdiction %in% c("NY STATE", "MCTD", "NY CITY")) |>
  mutate(grp = case_when(naics_industry_group == "2211" ~ "elec", naics_industry_group == "2212" ~ "gas",
                         naics_industry_group == "4247" ~ "petrol",
                         substr(naics_industry_group, 1, 2) == "22" ~ "other22", TRUE ~ "rest")) |>
  group_by(county = jurisdiction, grp) |> summarise(B = sum(B, na.rm = TRUE) / length(ANALYSIS_FYS), .groups = "drop") |>
  pivot_wider(names_from = grp, values_from = B, values_fill = 0) |>
  inner_join(pop_k, by = "county") |> inner_join(re_cw, by = "county") |>
  mutate(status = case_when(county_taxes_part1 ~ "County taxes residential energy",
                            school_district_or_city_only ~ "Only a school district or city taxes it",
                            TRUE ~ "No local tax on residential energy"),
         total = elec + gas + other22 + petrol + rest,
         elec_pc = elec / P, util_pc = (elec + gas + other22) / P, petrol_pc = petrol / P, total_pc = total / P)
R$re_test <- re_test |> select(county, status, P, elec_pc, util_pc, petrol_pc, total_pc)
R$re_summary <- re_test |> group_by(status) |>
  summarise(n = n(), elec_pc = median(elec_pc), util_pc = median(util_pc), petrol_pc = median(petrol_pc),
            total_pc = median(total_pc), .groups = "drop") |>
  arrange(factor(status, levels = c("County taxes residential energy", "Only a school district or city taxes it",
                                    "No local tax on residential energy")))
R$re_albany <- re_test |> filter(county == "ALBANY") |> select(elec_pc, util_pc, petrol_pc, total_pc)

## --- planning range ---------------------------------------------------------------------------
## Envelope of (i) the preferred 68% band at the upper end of sigma's 95% CI
## and (ii) every specification variant: exclusion set x functional form,
## business sharing rule (the plausible ones, i.e. not the floor and not the
## government-inclusive rule), calibration sample including the trusted
## subset, and the uncalibrated apportionment itself (the reviewer's point
## that apportioned taxable sales are a legitimate estimate in their own
## right). Rounded to $1 M.
plausible_alloc <- alloc_fits |> filter(!key %in% c("residence", "lodes"))
spec_revs <- c(rev(unlist(grid[, c("Log-log fit", "Slope fixed at 1", "Median ratio")])),
               plausible_alloc$rev, cv$rev, R$REV_trust, R$REV_raw,
               rev(est_pref$B_c_central * exp(-R$s_ci["hi"])), rev(est_pref$B_c_central * exp(R$s_ci["hi"])))
R$PLAN_LO <- round(min(spec_revs) / 1e6); R$PLAN_HI <- round(max(spec_revs) / 1e6)
R$BUDGET  <- floor(REV / 1e6)

R$generated <- Sys.time()
dir.create(PATHS$processed, recursive = TRUE, showWarnings = FALSE)
saveRDS(R, file.path(PATHS$processed, "results.rds"))
message(sprintf("06_results.R: saved %d objects to data/processed/results.rds in %.0f s. Revenue %.1f M, planning range %d-%d.",
                length(R), as.numeric(Sys.time() - t0, units = "secs"), REV / 1e6, R$PLAN_LO, R$PLAN_HI))
