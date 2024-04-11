#!/usr/bin/env bash

PWD=$(pwd)
BASE_FOLDER=$(basename "$PWD")
CLEAN_BASE_FOLDER=$(echo "$BASE_FOLDER" | sed -e 's/[^a-zA-Z0-9_]/_/g')
TARGET_FOLDER=${1:-.}

TEMP_FOLDER=$(mktemp -d)
MO="$TEMP_FOLDER"/mo

cleanup()
{
    rm -rf "$TEMP_FOLDER"
}

# Download MO bash mustache renderer
download_mo() 
{
    curl -sSL https://raw.githubusercontent.com/tests-always-included/mo/master/mo -o "$MO"
    chmod a+x "$MO"
}

read_input_with_default () {
    echo -n "[$1] > "
    read -r READ_INPUT_RETURN

    if [ -z "$READ_INPUT_RETURN" ]; then
        READ_INPUT_RETURN="$1"
    fi
}

run_mustache()
{
    FILES=$1
    for FILE in $FILES; do 
        $MO "$FILE" > "$TEMP_FOLDER"/tempfile
        mv -f "$TEMP_FOLDER"/tempfile "$TARGET_FOLDER/$FILE"
    done
}

exitWithError()
{
    echo "Error: $1"
    exit 1
}

check_valid() {
    if [[ "$HB_PACKAGE_NAME" =~ [^a-zA-Z0-9_] ]]; then
        exitWithError "Invalid package name: $HB_PACKAGE_NAME"
    fi
}
trap cleanup EXIT $?

download_mo
echo "Outputting to $TARGET_FOLDER"

echo -n "Enter your package name: "
read_input_with_default "$CLEAN_BASE_FOLDER"
export HB_PACKAGE_NAME=$READ_INPUT_RETURN
if [[ "$HB_PACKAGE_NAME" =~ [^a-zA-Z0-9_-] ]]; then
    exitWithError "Invalid package name: $HB_PACKAGE_NAME"
fi

echo -n "Enter your executable name: "
read_input_with_default "App"
export HB_EXECUTABLE_NAME=$READ_INPUT_RETURN
if [[ "$HB_EXECUTABLE_NAME" =~ [^a-zA-Z0-9_] ]]; then
    exitWithError "Invalid executable name: $HB_EXECUTABLE_NAME"
fi

if [[ "$TARGET_FOLDER" != "." ]]; then
    mkdir -p "$TARGET_FOLDER"/Sources/App
    mkdir -p "$TARGET_FOLDER"/Tests/AppTests
fi

# Root level files
FILES=$(find . -maxdepth 1 ! -type d ! -name "*.sh")
run_mustache "$FILES"
# Files in Sources and Tests folder
FILES=$(find Sources Tests ! -type d)
run_mustache "$FILES"




