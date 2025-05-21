#!/usr/bin/env bash
TEMPLATE_VERSION=2.0.4
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
