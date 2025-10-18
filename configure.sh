#!/usr/bin/env bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the Hummingbird server framework project
##
## Copyright (c) 2021-2025 the Hummingbird authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

TEMPLATE_FOLDER=$(dirname $0)

cleanup()
{
    rm -rf "$TEMP_FOLDER"
}

# Download MO bash mustache renderer
download_mo() 
{
    # v3.0.6 of mo is broken
    curl -sSL https://raw.githubusercontent.com/tests-always-included/mo/3.0.5/mo -o "$MO"
    chmod a+x "$MO"
}

read_input_with_default () {
    echo -n "[$1] > "
    read -r READ_INPUT_RETURN </dev/tty

    if [ -z "$READ_INPUT_RETURN" ]; then
        READ_INPUT_RETURN="$1"
    fi
}

yn_prompt () {
    if [[ "$1" == "yes" ]]; then
        echo "Y/n"
    else
        echo "y/N"
    fi
}

read_yes_no () {
    while [[ true ]]; do
        echo -n "[$(yn_prompt $1)] > "
        read -r READ_INPUT_RETURN </dev/tty

        case "$READ_INPUT_RETURN" in
            "y" | "Y")
                READ_INPUT_RETURN="yes"
                return
                ;;

            "n" | "N")
                READ_INPUT_RETURN="no"
                return
                ;;

            "")
                READ_INPUT_RETURN="$1"
                return
                ;;

            *)
                echo "Please input either \"y\" or \"n\", or press ENTER to use the default."
                ;;
        esac
    done
}

run_mustache()
{
    FILES=$1
    TARGET_FOLDER=$2
    TEMP_FILE="$TEMP_FOLDER"/tempfile
    for FILE in $FILES; do 
        $MO "$FILE" > "$TEMP_FILE"
        # delete file if it is empty or only contains spaces
        if ! grep -q '[^[:space:]]' "$TEMP_FILE" ; then
            echo "Removing $FILE"
            rm "$TEMP_FILE"
            if [ "$IN_PLACE_EDIT" = true ]; then
                rm "$TARGET_FOLDER/$FILE"
            fi
        else
            echo "Copying $FILE"
            mv -f "$TEMP_FILE" "$TARGET_FOLDER/$FILE"
        fi
    done
}

exitWithError()
{
    echo "Error: $1"
    exit 1
}

check_valid() {
    if [[ "$hbPackageName" =~ [^a-zA-Z0-9_] ]]; then
        exitWithError "Invalid package name: $hbPackageName"
    fi
}
trap cleanup EXIT $?

# Download Bash Mustache
TEMP_FOLDER=$(mktemp -d)
MO="$TEMP_FOLDER"/mo
download_mo

echo "Configuring your Hummingbird project"

RELATIVE_TARGET_FOLDER=${1:-}

# if no target folder is supplied ask for one
if [[ -z "$RELATIVE_TARGET_FOLDER" ]]; then
  echo ""
  echo -n "Enter your folder name: "
  read_input_with_default "my-app"
  export RELATIVE_TARGET_FOLDER=$READ_INPUT_RETURN
fi

# verify parent folder exists
PARENT_FOLDER=$(dirname "$RELATIVE_TARGET_FOLDER")
if [ ! -d "$PARENT_FOLDER" ]; then
    echo "$PARENT_FOLDER does not exist"
    exit -1
fi

TARGET_FOLDER=$(cd "$(dirname "$RELATIVE_TARGET_FOLDER")"; pwd -P)/$(basename "$RELATIVE_TARGET_FOLDER")

echo "Outputting to $TARGET_FOLDER"
mkdir -p "$TARGET_FOLDER"/Sources/App
mkdir -p "$TARGET_FOLDER"/Tests/AppTests
mkdir -p "$TARGET_FOLDER"/.vscode
mkdir -p "$TARGET_FOLDER"/.github/workflows

# get base folder of target folder so we can use that as default app name
BASE_FOLDER=$(basename "$TARGET_FOLDER")
CLEAN_BASE_FOLDER=$(echo "$BASE_FOLDER" | sed -e 's/[^a-zA-Z0-9_\-]/_/g')

echo ""
echo -n "Enter your Swift package name: "
read_input_with_default "$CLEAN_BASE_FOLDER"
export hbPackageName=$READ_INPUT_RETURN
if [[ "$hbPackageName" =~ [^a-zA-Z0-9_-] ]]; then
    exitWithError "Invalid package name: $hbPackageName"
fi

echo -n "Do you want to build an AWS Lambda function? "
read_yes_no "no"
if [[ "$READ_INPUT_RETURN" == "yes" ]]; then
    export hbLambda="yes"
    export hbExecutableName="App"
else
    echo -n "Enter your executable name: "
    read_input_with_default "App"
    export hbExecutableName=$READ_INPUT_RETURN
    if [[ "$hbExecutableName" =~ [^a-zA-Z0-9_] ]]; then
        exitWithError "Invalid executable name: $hbExecutableName"
    fi
fi

echo -n "Do you want to use the OpenAPI generator? "
read_yes_no "no"
if [[ "$READ_INPUT_RETURN" == "yes" ]]; then
    export hbOpenAPI="yes"
    mkdir -p "$TARGET_FOLDER"/Sources/AppAPI
fi

echo -n "Include Visual Studio Code snippets: "
read_yes_no "no"
if [[ "$READ_INPUT_RETURN" == "yes" ]]; then
    export hbVSCodeSnippets="yes"
fi

echo ""

pushd $TEMPLATE_FOLDER > /dev/null

# Root level files
FILES=$(find . -maxdepth 1 ! -type d ! -name "*.sh" ! -name LICENSE)
run_mustache "$FILES" "$TARGET_FOLDER"
# Files in Sources and Tests folder
FILES=$(find Sources Tests .github .vscode/hummingbird.code-snippets ! -type d)
run_mustache "$FILES" "$TARGET_FOLDER"

# README file
cat <<EOF | $MO > "$TARGET_FOLDER"/README.md
# $hbPackageName
Hummingbird server framework project
EOF

popd > /dev/null

echo ""
echo "Enter the folder $TARGET_FOLDER and run 'swift run' to build and run your server. Then open 'http://localhost:8080' in your web browser."
