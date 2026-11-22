#!/usr/bin/env bash
# skill/ here is a copy. Its source is skill/ in analyzify-mcp, and each
# connector release opens a skill-sync/<tag> PR with the new files. This check
# fails a PR that changes skill/ any other way, so the two cannot drift.
#
# A PR that changes skill/ passes only when:
# - its branch is skill-sync/v* in this repo (not a fork);
# - it changes nothing outside skill/;
# - every commit is the sync job's ("analyzify-mcp release");
# - SKILL.md's version is above main's and above every skill-v* tag, so the
#   release that merging runs (release-skill.yml) can publish it.
#
# It reads everything through the API, so it runs the same locally:
#   REPO=analyzify/analyzify-mcp-public PR=20 HEAD_REF=skill-sync/v0.4.26 \
#   HEAD_REPO=analyzify/analyzify-mcp-public BASE_REF=main HEAD_SHA=<sha> \
#   .github/scripts/skill-source-check.sh
set -euo pipefail
: "${REPO:?}" "${PR:?}"
SYNC_NAME="analyzify-mcp release"
HERE=$(cd "$(dirname "$0")" && pwd)
SOURCE="skill/ is built from the connector's release: change it in analyzify-mcp (skill/ there), and its next release opens a skill-sync PR here."

fail() {
  echo "::error::$1 $SOURCE"
  exit 1
}

files=$(gh api --paginate "repos/$REPO/pulls/$PR/files" --jq '.[] | .filename, (.previous_filename // empty)')
if ! grep -q '^skill/' <<<"$files"; then
  echo "No file under skill/ changes: nothing to check."
  exit 0
fi

: "${HEAD_REF:?}" "${BASE_REF:?}" "${HEAD_SHA:?}"
case "$HEAD_REF" in
skill-sync/v*) ;;
*) fail "This PR changes skill/ from the branch $HEAD_REF, not a skill-sync/v* branch." ;;
esac
[ "${HEAD_REPO:-}" = "$REPO" ] || fail "This PR's skill-sync branch is in ${HEAD_REPO:-a deleted fork}, not in $REPO."

other=$(grep -v '^skill/' <<<"$files" || true)
[ -z "$other" ] || fail "A skill-sync PR changes only skill/; this one also changes: $(tr '\n' ' ' <<<"$other")."

foreign=$(gh api --paginate "repos/$REPO/pulls/$PR/commits" \
  --jq ".[] | select(.commit.author.name != \"$SYNC_NAME\" or .commit.committer.name != \"$SYNC_NAME\") | .sha[0:7]")
[ -z "$foreign" ] || fail "Only the sync job's commits may change skill/; these are not: $(tr '\n' ' ' <<<"$foreign")."

skill_md() { gh api -H "Accept: application/vnd.github.raw+json" "repos/$REPO/contents/skill/SKILL.md?ref=$1"; }
head_md=$(skill_md "$HEAD_SHA") || fail "The PR's skill/SKILL.md could not be read (removed?)."
NEW=$("$HERE/skill-version.sh" <<<"$head_md") || fail "The PR's skill/SKILL.md has no x.y.z version line."
# main may have no SKILL.md yet (a 404); any other read error fails the check.
if ! base_md=$(skill_md "$BASE_REF" 2>&1); then
  grep -q 'HTTP 404' <<<"$base_md" || fail "$BASE_REF's skill/SKILL.md could not be read: $base_md."
  base_md=""
fi
OLD=$("$HERE/skill-version.sh" <<<"$base_md" 2>/dev/null) || OLD=0.0.0
LATEST=$(gh api --paginate "repos/$REPO/tags" --jq '.[].name | select(startswith("skill-v")) | ltrimstr("skill-v")' | sort -V | tail -1)
LATEST=${LATEST:-0.0.0}
above() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }
above "$NEW" "$OLD" || fail "SKILL.md's version $NEW is not above $BASE_REF's $OLD."
above "$NEW" "$LATEST" || fail "SKILL.md's version $NEW is not above the last skill tag, skill-v$LATEST."

echo "skill/ comes from the sync job (${HEAD_REF#skill-sync/}): skill $OLD -> $NEW (last tag skill-v$LATEST)."
