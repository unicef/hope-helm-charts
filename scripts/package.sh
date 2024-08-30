#!/bin/bash


if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  echo "Error: This script should be executed, not sourced." >&2
  return 1
fi

set -euo pipefail

CHART_DIR="charts"
OUTPUT_DIR="docs"
REPO_URL="https://unicef.github.io/hope-helm-charts/"

mkdir -p $OUTPUT_DIR

for chart in $(ls $CHART_DIR); do
  helm package $CHART_DIR/$chart -d $OUTPUT_DIR
done

helm repo index $OUTPUT_DIR --url $REPO_URL
