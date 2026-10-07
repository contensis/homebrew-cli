#!/usr/bin/env bash
#
# Bump Formula/contensis-cli.rb to a new contensis/cli release.
#
# Why a script exists for this: the formula serves one asset per platform from a
# single file, so a release is FOUR url/sha256 pairs plus the two `version` pins
# inside the arm64 branches. `brew bump-formula-pr` cannot do that — it rewrites
# only the top-level stable stanza (FormulaAST#replace_stable_stanza_value walks
# stable_children), so a URL inside `on_linux`/`on_macos` is invisible to it and
# the result is a half-bump that leaves one platform serving an old asset with a
# new sha (or the reverse, which fails the download). The mislav action in the
# CLI repo is no help either: it replaces only the first `url`/`sha256`/`version`
# line it finds and, with the `contensis-cli-` tag prefix, its version compare
# decides every tag is older than the formula and skips.
#
# This script rewrites all four pairs from the digests GitHub publishes for the
# release assets, so nothing is downloaded and no sha is hand-copied.
#
# Usage:
#   utils/bump-binary-formula.sh <version>              # e.g. 1.7.1
#   utils/bump-binary-formula.sh <version> --dry-run    # show the diff, write nothing
#   utils/bump-binary-formula.sh <version> --verify     # also run the tap CI checks
#
# Requires: gh, authenticated for the public API. brew as well, for --verify.

set -euo pipefail

FORMULA="Formula/contensis-cli.rb"
REPO="contensis/cli"
TAG_PREFIX="contensis-cli-v"
ASSETS=(
  "contensis-cli-mac"
  "contensis-cli-mac-arm64"
  "contensis-cli-linux"
  "contensis-cli-linux-arm64"
)

die() {
  echo "error: $*" >&2
  exit 1
}

VERSION="${1:-}"
[[ -n "${VERSION}" ]] || die "usage: ${0##*/} <version> [--dry-run|--verify]"
case "${VERSION}" in
  [0-9]*) ;;
  *) die "expected a bare version like 1.7.1, got '${VERSION}'" ;;
esac
case "${2:-}" in
  "--dry-run") DRY_RUN=1 ;;
  "--verify") VERIFY=1 ;;
  "") ;;
  *) die "unknown option '${2:-}' (expected --dry-run or --verify)" ;;
esac

command -v gh >/dev/null 2>&1 || die "gh is required (https://cli.github.com/)"

ROOT="$(git rev-parse --show-toplevel)"
cd "${ROOT}"
[[ -f "${FORMULA}" ]] || die "${FORMULA} not found — run this from the tap repository"

TAG="${TAG_PREFIX}${VERSION}"

# The GitHub API exposes a sha256 digest per release asset, so the shas come from
# the same source of truth the assets themselves are served from.
FILTER='.assets[] | select('
for i in "${!ASSETS[@]}"
do
  if [[ "${i}" -gt 0 ]]
  then
    FILTER+=' or '
  fi
  FILTER+=".name == \"${ASSETS[${i}]}\""
done
FILTER+=') | "\(.name) \(if .digest then (.digest | sub("^sha256:"; "")) else "MISSING" end)"'

RELEASE_JSON="$(gh api "repos/${REPO}/releases/tags/${TAG}" --jq "${FILTER}")" ||
  die "no release found for tag ${TAG} in ${REPO} (is it published?)"

MAP=""
for asset in "${ASSETS[@]}"
do
  sha="$(sed -n "s|^${asset} ||p" <<<"${RELEASE_JSON}")"
  [[ -n "${sha}" ]] || die "release ${TAG} has no ${asset} asset"
  case "${sha}" in
    MISSING) die "release ${TAG} publishes ${asset} without a digest (uploaded by an old runner?); compute it by hand" ;;
    *) ;;
  esac
  MAP+="${MAP:+;}${asset}=${sha}"
done

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Rewrites, for each of the four assets: the tag segment of its `url`, the
# `version` line if one sits between the url and its sha256 (the arm64 branches),
# and the `sha256` line that follows. Comments and the livecheck url are left
# alone — the livecheck reads /releases/latest, which is version-independent.
awk -v map="${MAP}" -v ver="${VERSION}" '
BEGIN {
  n = split(map, pairs, ";")
  for (i = 1; i <= n; i++) {
    eq = index(pairs[i], "=")
    digest[substr(pairs[i], 1, eq - 1)] = substr(pairs[i], eq + 1)
  }
}
{
  line = $0
  if (line ~ /^[ \t]*url "[^"]*\/releases\/download\/[^/]*\//) {
     url = line
     sub(/^[^"]*"/, "", url)
     sub(/".*$/, "", url)
     nseg = split(url, seg, "/")
     asset = seg[nseg]
     if (asset in digest) {
     newurl = url
     sub(/\/releases\/download\/[^/]*\//, "/releases/download/" tag "/", newurl)
     sub(/"[^"]*"/, "\"" newurl "\"", line)
     print line
     pending = asset
     next
     }
     }
        if (pending != "" && line ~ /^[ \t]*(version|sha256) "/) {
     match(line, /^[ \t]*/)
     indent = substr(line, 1, RLENGTH)
     if (line ~ /^[ \t]*version "/) {
     print indent "version \"" ver "\""
     } else {
     print indent "sha256 \"" digest[pending] "\""
     pending = ""
     done++
     }
     next
     }
     print
     }
     END {
        if (done != 4) {
     printf("expected 4 url/sha256 pairs, rewrote %d — refusing to write\n", done + 0) > "/dev/stderr"
     exit 3
     }
     }
     ' tag="${TAG}" "${FORMULA}" >"${TMP}"
     
     if [[ "${DRY_RUN:-0}" = 1 ]]
  then
  diff -u "${FORMULA}" "${TMP}" || true
  echo
  echo "dry run: nothing written. Release ${TAG} digests:"
  tr ';' '\n' <<<"${MAP}" | sed 's/^/  /'
  exit 0
fi

cat "${TMP}" >"${FORMULA}"
echo "bumped ${FORMULA} to ${TAG}"
tr ';' '\n' <<<"${MAP}" | sed 's/^/  /'
echo
echo "review with: git diff -- ${FORMULA}"

if [[ "${VERIFY:-0}" = 1 ]]
then
  command -v brew >/dev/null 2>&1 || die "brew is required for --verify"
  TAP_DIR="$(brew --repo contensis/cli 2>/dev/null || true)"
  if [[ "${TAP_DIR}" != "${ROOT}" ]]
  then
    echo "note: ${ROOT} is not the registered contensis/cli tap (${TAP_DIR})." >&2
    echo "      the checks below read that checkout, not this one." >&2
  fi
  echo
  echo "==> brew style contensis/cli"
  brew style contensis/cli
  echo "==> brew audit --except=installed --tap=contensis/cli"
  brew audit --except=installed --tap=contensis/cli
  echo "==> brew readall --os=all --arch=all"
  brew readall --os=all --arch=all
  echo "==> brew livecheck contensis/cli"
  brew livecheck contensis/cli
fi

echo
echo "the npm formula is a different job — it has one url, so the real command works:"
echo "  brew bump-formula-pr --url https://registry.npmjs.org/contensis-cli/-/contensis-cli-${VERSION}.tgz contensis-cli-spike"
