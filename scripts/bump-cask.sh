#!/usr/bin/env bash
# Bump Casks/facebook-messenger-app.rb to the latest upstream GitHub release.
#
# Reads the latest published (non-draft) release of the upstream repo,
# downloads its arm64 DMG, and rewrites the cask's `version` and `sha256`.
# Writes `changed=true|false` to $GITHUB_OUTPUT when running in Actions.
#
# Requires: gh (authenticated, or GH_TOKEN set), curl, perl, shasum or sha256sum.
set -euo pipefail

UPSTREAM="${UPSTREAM:-KHeresy/FacebookMessengerApp}"
CASK_FILE="${CASK_FILE:-Casks/facebook-messenger-app.rb}"

emit() {
  echo "$1"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "$1" >> "$GITHUB_OUTPUT"
  fi
}

sha256_of() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# Upstream tags look like v1.6.0+20261117 -> cask version "1.6.0,20261117".
tag="$(gh release view --repo "$UPSTREAM" --json tagName --jq .tagName)"
if [[ ! "$tag" =~ ^v([0-9]+(\.[0-9]+)+)\+([0-9]{8})$ ]]; then
  echo "Unexpected tag format: $tag" >&2
  exit 1
fi
app_version="${BASH_REMATCH[1]}"
build_date="${BASH_REMATCH[3]}"
latest="${app_version},${build_date}"

current="$(sed -n 's/^  version "\(.*\)"$/\1/p' "$CASK_FILE")"
echo "Current: ${current}"
echo "Latest:  ${latest}"

if [[ "$current" == "$latest" ]]; then
  echo "Cask is already up to date."
  emit "changed=false"
  exit 0
fi

url="https://github.com/${UPSTREAM}/releases/download/v${app_version}%2B${build_date}/Facebook.Messenger-${app_version}-arm64.dmg"
tmp_dmg="$(mktemp)"
trap 'rm -f "$tmp_dmg"' EXIT

echo "Downloading ${url}"
curl --fail --location --silent --show-error --output "$tmp_dmg" "$url"
sha="$(sha256_of "$tmp_dmg")"
echo "SHA256:  ${sha}"

LATEST="$latest" SHA="$sha" perl -pi -e '
  s/^  version ".*"$/  version "$ENV{LATEST}"/;
  s/^  sha256 ".*"$/  sha256 "$ENV{SHA}"/;
' "$CASK_FILE"

emit "changed=true"
emit "version=${latest}"
