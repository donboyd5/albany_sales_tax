#!/usr/bin/env bash
# Push the rendered site in _output/ to the gh-pages branch, from which GitHub
# Pages serves it. The project is a Quarto `default` project (not `website`),
# so `quarto publish gh-pages` refuses it; this does the same thing by hand.
# Usage: make publish   (renders first)   or   scripts/publish_gh_pages.sh
set -euo pipefail
cd "$(dirname "$0")/.."
REMOTE=$(git remote get-url origin)
[ -f _output/index.html ] || { echo "render first: quarto render" >&2; exit 1; }
rm -rf _output/.git
( cd _output \
  && git init -q -b gh-pages \
  && touch .nojekyll \
  && git add -A \
  && git -c user.name="$(git -C .. config user.name || echo publish)" \
         -c user.email="$(git -C .. config user.email || echo publish@localhost)" \
         commit -q -m "Publish site $(date -u +%Y-%m-%dT%H:%MZ) from $(git -C .. rev-parse --short HEAD)" \
  && git push -q -f "$REMOTE" gh-pages:gh-pages )
rm -rf _output/.git
echo "pushed gh-pages -> $REMOTE"
