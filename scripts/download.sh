#!/usr/bin/env bash
FOLDER=${1:-}
TEMPLATE_VERSION=2.0.3

if [[ -z "$FOLDER" ]]; then
  echo "Missing folder name"
  echo "Usage: download.sh <folder>"
  exit 1
fi

curl -sSL https://github.com/hummingbird-project/template/archive/refs/tags/"$TEMPLATE_VERSION".tar.gz | tar xvz -s /template-"$TEMPLATE_VERSION"/"$FOLDER"/
