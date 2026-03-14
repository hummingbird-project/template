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
        # Strip .mustache extension from output filename
        OUTPUT_FILE="${FILE%.mustache}"
        $MO "$FILE" > "$TEMP_FILE"
        # delete file if it is empty or only contains spaces
        if ! grep -q '[^[:space:]]' "$TEMP_FILE" ; then
            echo "Removing $OUTPUT_FILE"
            rm "$TEMP_FILE"
            if [ "$IN_PLACE_EDIT" = true ]; then
                rm "$TARGET_FOLDER/$OUTPUT_FILE"
            fi
        else
            echo "Copying $OUTPUT_FILE"
            mv -f "$TEMP_FILE" "$TARGET_FOLDER/$OUTPUT_FILE"
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

# Parse optional flags for non-interactive usage
FLAG_PACKAGE_NAME=""
FLAG_EXECUTABLE_NAME=""
FLAG_LAMBDA=""
FLAG_OPENAPI=""
FLAG_VSCODE_SNIPPETS=""
FLAG_DEFAULTS=""

show_help() {
    echo "Usage: configure.sh [TARGET_FOLDER] [OPTIONS]"
    echo ""
    echo "Configure a new Hummingbird project."
    echo ""
    echo "Options:"
    echo "  --package-name NAME      Set the Swift package name"
    echo "  --executable-name NAME   Set the executable target name"
    echo "  --lambda                 Build as an AWS Lambda function"
    echo "  --openapi                Use the OpenAPI generator"
    echo "  --vscode-snippets        Include Visual Studio Code snippets"
    echo "  --defaults               Use default values for any option not set by a flag"
    echo "  --help                   Show this help message and exit"
    exit 0
}

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --package-name)
            FLAG_PACKAGE_NAME="$2"
            shift 2
            ;;
        --executable-name)
            FLAG_EXECUTABLE_NAME="$2"
            shift 2
            ;;
        --lambda)
            FLAG_LAMBDA="yes"
            shift
            ;;
        --openapi)
            FLAG_OPENAPI="yes"
            shift
            ;;
        --vscode-snippets)
            FLAG_VSCODE_SNIPPETS="yes"
            shift
            ;;
        --defaults)
            FLAG_DEFAULTS="yes"
            shift
            ;;
        --help)
            show_help
            ;;
        -*)
            exitWithError "Unknown option: $1"
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Download Bash Mustache
TEMP_FOLDER=$(mktemp -d)
MO="$TEMP_FOLDER"/mo
download_mo

echo "Configuring your Hummingbird project"

RELATIVE_TARGET_FOLDER=${POSITIONAL_ARGS[0]:-}

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

# Package name
if [[ -n "$FLAG_PACKAGE_NAME" ]]; then
    export hbPackageName="$FLAG_PACKAGE_NAME"
elif [[ -n "$FLAG_DEFAULTS" ]]; then
    export hbPackageName="$CLEAN_BASE_FOLDER"
else
    echo ""
    echo -n "Enter your Swift package name: "
    read_input_with_default "$CLEAN_BASE_FOLDER"
    export hbPackageName=$READ_INPUT_RETURN
fi
if [[ "$hbPackageName" =~ [^a-zA-Z0-9_-] ]]; then
    exitWithError "Invalid package name: $hbPackageName"
fi

# Lambda
if [[ -n "$FLAG_LAMBDA" ]]; then
    export hbLambda="yes"
    export hbLambdaType="APIGatewayV2"
    export hbExecutableName="App"
elif [[ -n "$FLAG_DEFAULTS" ]]; then
    export hbLambda=""
    # Executable name
    if [[ -n "$FLAG_EXECUTABLE_NAME" ]]; then
        export hbExecutableName="$FLAG_EXECUTABLE_NAME"
    else
        export hbExecutableName="App"
    fi
    if [[ "$hbExecutableName" =~ [^a-zA-Z0-9_] ]]; then
        exitWithError "Invalid executable name: $hbExecutableName"
    fi
else
    echo -n "Do you want to build an AWS Lambda function? "
    read_yes_no "no"
    if [[ "$READ_INPUT_RETURN" == "yes" ]]; then
        export hbLambda="yes"
        export hbLambdaType="APIGatewayV2"
        export hbExecutableName="App"
    else
        export hbLambda=""
        # Executable name
        if [[ -n "$FLAG_EXECUTABLE_NAME" ]]; then
            export hbExecutableName="$FLAG_EXECUTABLE_NAME"
        else
            echo -n "Enter your executable name: "
            read_input_with_default "App"
            export hbExecutableName=$READ_INPUT_RETURN
        fi
        if [[ "$hbExecutableName" =~ [^a-zA-Z0-9_] ]]; then
            exitWithError "Invalid executable name: $hbExecutableName"
        fi
    fi
fi

# OpenAPI
if [[ -n "$FLAG_OPENAPI" ]]; then
    export hbOpenAPI="yes"
    mkdir -p "$TARGET_FOLDER"/Sources/AppAPI
elif [[ -n "$FLAG_DEFAULTS" ]]; then
    export hbOpenAPI=""
else
    echo -n "Do you want to use the OpenAPI generator? "
    read_yes_no "no"
    if [[ "$READ_INPUT_RETURN" == "yes" ]]; then
        export hbOpenAPI="yes"
        mkdir -p "$TARGET_FOLDER"/Sources/AppAPI
    else
        export hbOpenAPI=""
    fi
fi

# VS Code snippets
if [[ -n "$FLAG_VSCODE_SNIPPETS" ]]; then
    export hbVSCodeSnippets="yes"
elif [[ -n "$FLAG_DEFAULTS" ]]; then
    export hbVSCodeSnippets=""
else
    echo -n "Include Visual Studio Code snippets: "
    read_yes_no "no"
    if [[ "$READ_INPUT_RETURN" == "yes" ]]; then
        export hbVSCodeSnippets="yes"
    else
        export hbVSCodeSnippets=""
    fi
fi

echo ""

pushd $TEMPLATE_FOLDER > /dev/null

# Root level files
FILES=$(find . -maxdepth 1 ! -type d ! -name "*.sh" ! -name LICENSE ! -name ".DS_Store")
run_mustache "$FILES" "$TARGET_FOLDER"
# Files in Sources and Tests folder
FILES=$(find Sources Tests .github .vscode/hummingbird.code-snippets ! -type d ! -name "test-configure.yml")
run_mustache "$FILES" "$TARGET_FOLDER"

# README file
cat <<EOF | $MO > "$TARGET_FOLDER"/README.md
# $hbPackageName
Hummingbird server framework project
EOF

popd > /dev/null

echo ""
echo "Enter the folder $TARGET_FOLDER and run 'swift run' to build and run your server. Then open 'http://localhost:8080' in your web browser."
