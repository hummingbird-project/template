#!/usr/bin/env bash

PWD=$(pwd)
TARGET_FOLDER=${1:-$PWD}
BASE_FOLDER=$(basename $TARGET_FOLDER)
CLEAN_BASE_FOLDER=$(echo "$BASE_FOLDER" | sed -e 's/[^a-zA-Z0-9_]/_/g')

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

run_mustache-template()
{
    echo $1 
    #| $MO > "$TEMP_FOLDER"/$2
    echo $2
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

echo "Configuring your Hummingbird project"

# Download Bash Mustache
download_mo

if [[ "$TARGET_FOLDER" != "$PWD" ]]; then
    echo "Outputting to $TARGET_FOLDER"
    mkdir -p "$TARGET_FOLDER"/Sources/App
    mkdir -p "$TARGET_FOLDER"/Tests/AppTests
else
    echo "Outputting to current folder"
fi



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

# Root level files
FILES=$(find . -maxdepth 1 ! -type d ! -name "*.sh")
run_mustache "$FILES"
# Files in Sources and Tests folder
FILES=$(find Sources Tests ! -type d)
run_mustache "$FILES"

# README file
cat <<EOF | $MO > $TARGET_FOLDER/README.md
# $HB_PACKAGE_NAME
My awesome project
EOF
