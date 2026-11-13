#!/bin/bash
# Packages the given charts into docs/ and adds them to docs/index.yaml.
#
# Usage: scripts/package.sh <chart> [<chart>...]
#
# A chart version that is already published (docs/<name>-<version>.tgz or an
# index.yaml entry) is never repackaged: bump the chart version instead.
# Existing packages and index entries are left as they are.
# Dependencies come from Chart.lock (helm dependency build); charts with
# https:// dependency repositories need them added first (helm repo add).

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  echo "Error: This script should be executed, not sourced." >&2
  return 1
fi

set -euo pipefail

cd "$(dirname "$0")/.."

CHART_DIR="charts"
OUTPUT_DIR="docs"
REPO_URL="https://unicef.github.io/hope-helm-charts/"

usage() {
  echo "Usage: $0 <chart> [<chart>...]" >&2
  echo "Charts: $(ls "$CHART_DIR" | tr '\n' ' ')" >&2
  exit 2
}

chart_field() { # <chart> <field>
  helm show chart "$CHART_DIR/$1" | sed -n "s/^$2: *//p" | tr -d '"'
}

# Fails before anything is built if a chart is unknown or its version is published
check_chart() {
  local chart=$1 name version package
  if [ ! -f "$CHART_DIR/$chart/Chart.yaml" ]; then
    echo "Error: $CHART_DIR/$chart is not a chart." >&2
    exit 1
  fi
  name=$(chart_field "$chart" name)
  version=$(chart_field "$chart" version)
  package="$name-$version.tgz"
  if [ -e "$OUTPUT_DIR/$package" ]; then
    echo "Error: $OUTPUT_DIR/$package already exists; bump the version in $CHART_DIR/$chart/Chart.yaml instead of repackaging it." >&2
    exit 1
  fi
  if [ -f "$OUTPUT_DIR/index.yaml" ] && grep -qF "/$package" "$OUTPUT_DIR/index.yaml"; then
    echo "Error: $package is already listed in $OUTPUT_DIR/index.yaml; bump the version in $CHART_DIR/$chart/Chart.yaml." >&2
    exit 1
  fi
  echo "Will publish $package"
}

main() {
  [ $# -ge 1 ] || usage

  echo "Using helm $(helm version --template '{{.Version}}')"

  for chart in "$@"; do
    check_chart "$chart"
  done

  mkdir -p "$OUTPUT_DIR"
  local tmp
  tmp=$(mktemp -d)
  # expanded now: the trap runs after main has returned and $tmp is gone
  trap "rm -rf '$tmp'" EXIT

  for chart in "$@"; do
    echo "Building dependencies for chart: $chart (from Chart.lock)"
    helm dependency build "$CHART_DIR/$chart"
    helm package "$CHART_DIR/$chart" -d "$tmp"
  done

  # Index only the new packages and merge the existing index in, so published
  # entries keep their digests, URLs and creation dates
  if [ -f "$OUTPUT_DIR/index.yaml" ]; then
    helm repo index "$tmp" --url "$REPO_URL" --merge "$OUTPUT_DIR/index.yaml"
  else
    helm repo index "$tmp" --url "$REPO_URL"
  fi

  for package in "$tmp"/*.tgz; do
    if [ -e "$OUTPUT_DIR/$(basename "$package")" ]; then
      echo "Error: $OUTPUT_DIR/$(basename "$package") appeared while packaging; not overwriting it." >&2
      exit 1
    fi
  done
  cp "$tmp"/*.tgz "$OUTPUT_DIR/"
  cp "$tmp/index.yaml" "$OUTPUT_DIR/index.yaml"
  echo "Published to $OUTPUT_DIR: $(cd "$tmp" && ls *.tgz | tr '\n' ' ')"
}

main "$@"
