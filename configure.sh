#!/usr/bin/env bash
PWD=$(pwd)
TEMPLATE_FOLDER=$(dirname $0)
RELATIVE_TARGET_FOLDER=${1:-}
TARGET_FOLDER=$(cd "$(dirname "$RELATIVE_TARGET_FOLDER")"; pwd -P)/$(basename "$RELATIVE_TARGET_FOLDER")
BASE_FOLDER=$(basename "$TARGET_FOLDER")
CLEAN_BASE_FOLDER=$(echo "$BASE_FOLDER" | sed -e 's/[^a-zA-Z0-9_]/_/g')

TEMP_FOLDER=$(mktemp -d)
MO="$TEMP_FOLDER"/mo

if [ "$TARGET_FOLDER" = "$PWD/" ]; then
    IN_PLACE_EDIT=true
else
    IN_PLACE_EDIT=false
fi

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
    read -r READ_INPUT_RETURN

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
        read -r READ_INPUT_RETURN

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
    TEMP_FILE="$TEMP_FOLDER"/tempfile
    for FILE in $FILES; do 
        $MO "$FILE" > "$TEMP_FILE"
        # delete file if it is empty or only contains spaces
        if ! grep -q '[^[:space:]]' "$TEMP_FILE" ; then
            echo "Removing $FILE"
            rm "$TEMP_FILE"
            rm "$TARGET_FOLDER/$FILE"
        else
            if [ "$IN_PLACE_EDIT" = true ]; then
                echo "Updating $FILE"
            else
                echo "Copying $FILE"
            fi    
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
    if [[ "$HB_PACKAGE_NAME" =~ [^a-zA-Z0-9_] ]]; then
        exitWithError "Invalid package name: $HB_PACKAGE_NAME"
    fi
}
trap cleanup EXIT $?

echo "Configuring your Hummingbird project"

# Download Bash Mustache
download_mo

if [ "$IN_PLACE_EDIT" = false ]; then
    echo "Outputting to $TARGET_FOLDER"
    mkdir -p "$TARGET_FOLDER"/Sources/App
    mkdir -p "$TARGET_FOLDER"/Tests/AppTests
    mkdir -p "$TARGET_FOLDER"/.vscode
else
    echo "Outputting to current folder"
fi

echo ""
echo -n "Enter your Swift package name: "
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

echo -n "Include Visual Studio Code snippets: "
read_yes_no "yes"
if [[ "$READ_INPUT_RETURN" == "yes" ]]; then
    export HB_VSCODE_SNIPPETS="yes"
fi

echo ""

pushd $TEMPLATE_FOLDER > /dev/null

# Root level files
FILES=$(find . -maxdepth 1 ! -type d ! -name "*.sh")
run_mustache "$FILES"
# Files in Sources and Tests folder
FILES=$(find Sources Tests .vscode/hummingbird.code-snippets ! -type d)
run_mustache "$FILES"

# README file
cat <<EOF | $MO > "$TARGET_FOLDER"/README.md
# $HB_PACKAGE_NAME
Hummingbird server framework project
EOF

popd > /dev/null

echo ""
if [ "$IN_PLACE_EDIT" = true ]; then
    echo "Run 'swift run' to build and run your server. Then open 'http://localhost:8080' in your web browser."
else
    echo "Enter the folder $TARGET_FOLDER and run 'swift run' to build and run your server. Then open 'http://localhost:8080' in your web browser."
fi
