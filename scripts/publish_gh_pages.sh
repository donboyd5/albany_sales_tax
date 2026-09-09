#!/usr/bin/env bash
# Publish the rendered site to the gh-pages branch, from which GitHub Pages
# serves it. By default every HTML page is first encrypted with StatiCrypt
# (https://github.com/robinmoisson/staticrypt) using the password in
# .site_password (git-ignored), so visitors must enter it once; the browser
# remembers it for 30 days. Pass --public to publish unencrypted.
# Usage: make publish   (renders first)   or   scripts/publish_gh_pages.sh [--public]
set -euo pipefail
cd "$(dirname "$0")/.."
REMOTE=$(git remote get-url origin)
[ -f _output/index.html ] || { echo "render first: quarto render" >&2; exit 1; }

SRC=_output
if [ "${1:-}" != "--public" ]; then
  [ -f .site_password ] || { echo "no .site_password file; create one or pass --public" >&2; exit 1; }
  export STATICRYPT_PASSWORD
  STATICRYPT_PASSWORD=$(head -n1 .site_password)
  rm -rf _output_enc
  # run from inside _output so the encrypted tree keeps the same relative paths;
  # the salt lives in .staticrypt.json (committed) so "remember me" survives republishing
  ( cd _output && npx --yes staticrypt . -r -d ../_output_enc --remember 30 --short -c ../.staticrypt.json >/dev/null )
  # staticrypt nests the output under the input directory's name; flatten it
  if [ -d _output_enc/_output ]; then
    ( cd _output_enc/_output && find . -mindepth 1 -maxdepth 1 -exec mv -t .. -- {} + ) && rmdir _output_enc/_output
  fi
  # copy non-HTML assets (css, js, images) that staticrypt does not carry across
  rsync -a --exclude '*.html' --exclude 'search.json' _output/ _output_enc/
  # the search index and sitemap would expose page text and structure outside the password
  rm -f _output_enc/search.json _output_enc/sitemap.xml
  # every HTML page must now be an encrypted shell
  if grep -L 'staticrypt' $(find _output_enc -name '*.html') | grep -q .; then
    echo "some pages were not encrypted:" >&2; grep -L 'staticrypt' $(find _output_enc -name '*.html') >&2; exit 1
  fi
  SRC=_output_enc
  echo "encrypted $(find _output_enc -name '*.html' | wc -l) pages"
fi

rm -rf "$SRC/.git"
( cd "$SRC" \
  && git init -q -b gh-pages \
  && touch .nojekyll \
  && git add -A \
  && git -c user.name="$(git -C .. config user.name || echo publish)" \
         -c user.email="$(git -C .. config user.email || echo publish@localhost)" \
         commit -q -m "Publish site $(date -u +%Y-%m-%dT%H:%MZ) from $(git -C .. rev-parse --short HEAD)${SRC:+ ($SRC)}" \
  && git push -q -f "$REMOTE" gh-pages:gh-pages )
rm -rf "$SRC/.git"
echo "pushed gh-pages -> $REMOTE (${SRC})"
