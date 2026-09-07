# Convenience targets. Every step is also runnable by hand; see README.md.

.PHONY: pulls render memo site publish urls

pulls:            ## fetch/cached-read every source (idempotent; uses data/raw/ cache)
	Rscript R/01_pull_dtf.R
	Rscript R/02_pull_census_ec.R
	Rscript R/03_pull_acs_lodes_dmv.R
	Rscript R/05_calibrate.R

render:           ## render the site into _output/ and refresh docs/albany-halfpct-memo.md
	quarto render
	cp _output/analysis/memo.md docs/albany-halfpct-memo.md

memo: render      ## alias

urls:             ## check that every cited URL still resolves
	Rscript R/99_check_urls.R

publish: render   ## render and push the site to the gh-pages branch (GitHub Pages)
	scripts/publish_gh_pages.sh
