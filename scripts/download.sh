#!/usr/bin/env bash
TEMPLATE_VERSION=$(git ls-remote --tags --refs https://github.com/hummingbird-project/template | sed -E 's/.*refs\/tags\/(.*)/\1/' | sort --version-sort | tail -n 1)
TEMP_DIR=$(mktemp -d)

trap cleanup EXIT $?

cleanup()
{
    if [ -n "$TEMP_DIR" ]; then
        rm -rf $TEMP_DIR
    fi
}

# Run curl and extract to temp folder
curl -sSL https://github.com/hummingbird-project/template/archive/refs/tags/"$TEMPLATE_VERSION".tar.gz | tar xvz -C $TEMP_DIR
# Run configure.sh
"$TEMP_DIR"/template-"$TEMPLATE_VERSION"/configure.sh
