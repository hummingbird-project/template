#!/usr/bin/env bash
FOLDER=${1:-}
TEMPLATE_VERSION=2.0.0-beta.1

if [[ -z "$FOLDER" ]]; then
  echo "Missing folder name"
  echo "Usage: download.sh <folder>"
  exit 1
fi

curl -L https://codeload.github.com/hummingbird-project/template/tar.gz/refs/tags/"$TEMPLATE_VERSION" | tar xvz -s /template-2.0.0-beta.1/"$FOLDER"/