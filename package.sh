#!/bin/bash
set -e

# Script to package Helm chart and update repository index
# Usage: ./package.sh

echo "=========================================="
echo "Packaging Netmaker Helm Chart"
echo "=========================================="
echo ""

# Step 1: Build dependencies (downloads postgresql-ha chart)
echo "Step 1: Building chart dependencies..."
helm dependency build

# Step 2: Package the chart
echo ""
echo "Step 2: Packaging chart..."
CHART_VERSION=$(grep "^version:" Chart.yaml | awk '{print $2}')
CHART_NAME=$(grep "^name:" Chart.yaml | awk '{print $2}')
helm package .

# Step 3: Update repository index (only netmaker-*.tgz; exclude charts/ vendored dependencies)
echo ""
echo "Step 3: Updating repository index..."
INDEX_TMP=$(mktemp -d)
trap 'rm -rf "$INDEX_TMP"' EXIT
cp netmaker-*.tgz "$INDEX_TMP/"
helm repo index "$INDEX_TMP" --url https://gravitl.github.io/netmaker-helm/ --merge index.yaml
mv "$INDEX_TMP/index.yaml" index.yaml

echo ""
echo "=========================================="
echo "Packaging Complete!"
echo "=========================================="
echo ""
echo "Chart packaged: ${CHART_NAME}-${CHART_VERSION}.tgz"
echo ""
echo "Next steps:"
echo "  1. Review the package: ls -lh ${CHART_NAME}-${CHART_VERSION}.tgz"
echo "  2. Commit and push changes:"
echo "     git add Chart.yaml Chart.lock charts/ values.yaml templates/ ${CHART_NAME}-${CHART_VERSION}.tgz index.yaml README.md package.sh"
echo "     git commit -m 'Update chart to version ${CHART_VERSION}'"
echo "     git push"
echo ""

