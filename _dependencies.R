## _dependencies.R ---------------------------------------------------------
## Not executed. renv's dependency scanner reads this file so that every
## package the project is committed to using is captured in renv.lock, even
## before the script that uses it has been written (renv discovers
## dependencies from library() calls in .R/.qmd sources).
##
## Keep this list in sync with the package list in README.md / CLAUDE.md.
## -------------------------------------------------------------------------

library(httr2)      # Socrata + raw Census requests
library(jsonlite)   # JSON parsing
library(dplyr)      # data manipulation
library(tidyr)      # reshaping
library(purrr)      # functional iteration over pulls
library(readr)      # csv IO
library(stringr)    # string handling
library(readxl)     # DTF AS001 .xlsx certifications
library(rvest)      # scraping the AS001 index page for xlsx links
library(censusapi)  # Economic Census, ACS, decennial pulls
library(lehdr)      # LEHD LODES WAC + geography crosswalk
library(gt)         # formatted tables in the qmd
library(ggplot2)    # plots
library(broom)      # tidying the calibration fit
library(sandwich)   # clustered variance for the calibration
library(lmtest)     # coeftest() against the clustered vcov
library(digest)     # sha256 for data/raw/MANIFEST.csv
library(here)       # project-root-relative paths
