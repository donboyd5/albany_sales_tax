# Convenience targets. Every step is also runnable by hand; see README.md.

.PHONY: pulls results render render-all site publish urls

pulls:            ## fetch/cached-read every source (idempotent; uses data/raw/ cache)
	Rscript R/01_pull_dtf.R
	Rscript R/02_pull_census_ec.R
	Rscript R/03_pull_acs_lodes_dmv.R
	Rscript R/05_calibrate.R

results:          ## compute every number the book reports -> data/processed/results.rds
	Rscript R/06_results.R

render:           ## render the book into _output/ (run `make results` first if data or code changed)
	quarto render

render-all:       ## same, but also re-execute the two frozen technical appendices (needed after R code changes)
	rm -rf _freeze
	quarto render

site: render      ## alias

urls:             ## check that every cited URL still resolves
	Rscript R/99_check_urls.R

publish: render   ## render and push the site to the gh-pages branch (GitHub Pages)
	scripts/publish_gh_pages.sh
