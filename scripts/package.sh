#!/bin/bash

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  echo "Error: This script should be executed, not sourced." >&2
  return 1
fi

set -euo pipefail

cd "$(dirname "$0")/.."

CHART_DIR="charts"
OUTPUT_DIR="docs"
REPO_URL="https://unicef.github.io/hope-helm-charts/"

create_output_dir() {
  mkdir -p $OUTPUT_DIR
}

package_chart() {
  local chart=$1
  if [ -d "$CHART_DIR/$chart" ]; then
    echo "Updating dependencies for chart: $chart"
    helm dependency update "$CHART_DIR/$chart"
    helm package "$CHART_DIR/$chart" -d $OUTPUT_DIR
  else
    echo "Error: Directory $CHART_DIR/$chart does not exist." >&2
    exit 1
  fi
}

package_all_charts() {
  for chart in $(ls $CHART_DIR); do
    package_chart $chart
  done
}

update_repo_index() {
  helm repo index $OUTPUT_DIR --url $REPO_URL
}

main() {
  create_output_dir

  if [ $# -eq 1 ]; then
    package_chart $1
  else
    package_all_charts
  fi

  update_repo_index
}

main "$@"