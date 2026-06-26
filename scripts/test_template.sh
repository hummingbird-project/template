#!/usr/bin/env bash
##===----------------------------------------------------------------------===##
##
## Tests for configure.sh non-interactive flag support
##
##===----------------------------------------------------------------------===##

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TEMPLATE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
CONFIGURE="hb"
BASE_OPTIONS="init --template ."

PASS_COUNT=0
FAIL_COUNT=0
TEST_TMPDIR=""

setup() {
    TEST_TMPDIR=$(mktemp -d)
}

teardown() {
    if [ -n "$TEST_TMPDIR" ]; then
        rm -rf "$TEST_TMPDIR"
    fi
}

assert_file_contains() {
    local file="$1"
    local expected="$2"
    local msg="$3"
    if [ ! -f "$file" ]; then
        echo "  FAIL: $msg — file not found: $file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi
    if grep -q "$expected" "$file"; then
        echo "  PASS: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL: $msg — expected '$expected' in $file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local msg="$3"
    if [ ! -f "$file" ]; then
        echo "  PASS: $msg (file does not exist)"
        PASS_COUNT=$((PASS_COUNT + 1))
        return
    fi
    if grep -q "$pattern" "$file"; then
        echo "  FAIL: $msg — did not expect '$pattern' in $file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo "  PASS: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="$2"
    if [ -f "$file" ]; then
        echo "  PASS: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL: $msg — file not found: $file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_dir_exists() {
    local dir="$1"
    local msg="$2"
    if [ -d "$dir" ]; then
        echo "  PASS: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL: $msg — directory not found: $dir"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_dir_not_exists() {
    local dir="$1"
    local msg="$2"
    if [ ! -d "$dir" ]; then
        echo "  PASS: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL: $msg — directory should not exist: $dir"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_exit_code() {
    local actual="$1"
    local expected="$2"
    local msg="$3"
    if [ "$actual" -eq "$expected" ]; then
        echo "  PASS: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL: $msg — expected exit code $expected, got $actual"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# ============================================================================
# Test: Fully non-interactive with all flags
# ============================================================================
test_all_flags() {
    echo "TEST: All flags provided (fully non-interactive)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/MyApp"

    "$CONFIGURE" $BASE_OPTIONS \
        --answer name=MyServer \
        --answer features=openapi,websockets,vscode \
         "$OUTPUT_DIR" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_exists "$OUTPUT_DIR/Package.swift" "Package.swift is created"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "MyApp" "Package.swift contains package name"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "MyServer" "Package.swift contains executable name"
    assert_dir_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI Sources/AppAPI directory created"
    assert_file_exists "$OUTPUT_DIR/README.md" "README.md is created"
    assert_file_contains "$OUTPUT_DIR/README.md" "MyApp" "README.md contains package name"

    teardown
}

# ============================================================================
# Test: Fully non-interactive with --answer app=lambda flag
# ============================================================================
test_lambda_type() {
    echo "TEST: Lambda flag (fully non-interactive)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/LambdaApp"

    "$CONFIGURE" $BASE_OPTIONS \
        --answer app=lambda \
         "$OUTPUT_DIR" \
         </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_exists "$OUTPUT_DIR/Package.swift" "Package.swift is created"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "LambdaApp" "Package.swift contains package name"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Package.swift contains Lambda dependency"

    teardown
}

# ============================================================================
# Test: Minimal with --answer name=MinimalApp
# ============================================================================
test_minimal_flags() {
    echo "TEST: Minimal flags (only --answer name=MinimalApp)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/MinimalApp"

    "$CONFIGURE" $BASE_OPTIONS \
        --answer name=minimal-app \
        "$OUTPUT_DIR" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_exists "$OUTPUT_DIR/Package.swift" "Package.swift is created"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "minimal-app" "Package.swift contains package name"
    assert_file_not_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda is not enabled"
    assert_dir_not_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI directory not created"

    teardown
}

# ============================================================================
# Test: Only --answer features=openapi — package name defaults to folder basename
# ============================================================================
test_openapi_only() {
    echo "TEST: Only --openapi (package name defaults to folder basename)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/my_project"

    "$CONFIGURE" $BASE_OPTIONS \
        --answer features=openapi \
        "$OUTPUT_DIR" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "my_project" "package name defaults to cleaned folder basename"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "App" "executable defaults to App"
    assert_dir_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI directory created"
    assert_file_not_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda defaults to off"

    teardown
}

# ============================================================================
# Test: Only --answer features=websockets
# ============================================================================
test_websockets_only() {
    echo "TEST: Only --openapi (package name defaults to folder basename)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/my_project"

    "$CONFIGURE" $BASE_OPTIONS \
        --answer features=websockets \
        "$OUTPUT_DIR" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "my_project" "package name defaults to cleaned folder basename"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "App" "executable defaults to App"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "hummingbird-websocket" "Package.swift contains WebSocket dependency"
    assert_file_contains "$OUTPUT_DIR/Sources/App/App+build.swift" "buildWebSocketRouter" "App+build.swift contains buildWebSocketRouter function"

    teardown
}

# ============================================================================
# Test: Invalid package name via flag
# ============================================================================
test_invalid_package_name() {
    echo "TEST: Invalid package name via flag"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/badname"

    "$CONFIGURE" $BASE_OPTIONS \
        --answer name="Bad Name!" \
        "$OUTPUT_DIR" \
        </dev/null 2>&1

    assert_exit_code $? 1 "exits with error for invalid package name"

    teardown
}

# ============================================================================
# Test: Unknown option --answer features=bells,whistles
# ============================================================================
test_unknown_option() {
    echo "TEST: Unknown flag produces error"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/unknownflag"

    "$CONFIGURE" $BASE_OPTIONS \
        --answer features=bells,whistles \
        "$OUTPUT_DIR" \
        </dev/null 2>&1

    assert_exit_code $? 1 "exits with error for unknown flag"

    teardown
}

# ============================================================================
# Test: Generated project contains valid ci.yml
# ============================================================================
test_generated_ci_yml() {
    echo "TEST: Generated project contains valid ci.yml"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/citest"

    "$CONFIGURE" $BASE_OPTIONS \
        --answer name="CITest" \
        "$OUTPUT_DIR" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_exists "$OUTPUT_DIR/.github/workflows/ci.yml" "ci.yml exists in generated project"
    assert_file_not_contains "$OUTPUT_DIR/.github/workflows/ci.yml" "{{hb" "ci.yml does not contain mustache syntax"

    teardown
}

# ============================================================================
# Expect-based interactive tests
# ============================================================================

# Helper: run an expect script and capture its exit code.
# Writes expect output to $TEST_TMPDIR/expect_output for assertions.
run_expect() {
    local expect_script="$1"
    expect -c "$expect_script" > "$TEST_TMPDIR/expect_output" 2>&1
    return $?
}

# ============================================================================
# Test: Fully interactive — all prompts appear, all defaults accepted
# ============================================================================
test_interactive_all_defaults() {
    echo "TEST: Fully interactive — accept all defaults"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/interactive_defaults"

    run_expect "
        set timeout 30
        spawn $CONFIGURE $BASE_OPTIONS $OUTPUT_DIR
        expect \"What kind of application are you building\"
        send \"\r\"
        expect \"What would you like your executable to be named?\"
        send \"App\r\"
        expect \"Which features would you like to enable?\"
        send \"\r\"
        expect eof
        catch wait result
        exit [lindex \$result 3]
    "
    assert_exit_code $? 0 "exits successfully"
    assert_file_exists "$OUTPUT_DIR/Package.swift" "Package.swift is created"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "interactive_defaults" "package name defaults to folder basename"
    assert_file_not_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda defaults to off"
    assert_dir_not_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI defaults to off"

    teardown
}

# ============================================================================
# Test: Fully interactive — provide custom values
# ============================================================================
test_interactive_custom_values() {
    echo "TEST: Fully interactive — custom values"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/interactive_custom"

    run_expect "
        set timeout 30
        spawn $CONFIGURE $BASE_OPTIONS $OUTPUT_DIR
        expect \"What kind of application are you building\"
        send \"\r\"
        expect \"What would you like your executable to be named?\"
        send \"CustomPkg\r\"
        expect \"Which features would you like to enable?\"
        send \" \r\"
        expect eof
        catch wait result
        exit [lindex \$result 3]
    "
    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "CustomPkg" "package name is CustomPkg"
    assert_dir_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI directory created"

    teardown
}

# ============================================================================
# Test: Everything enabled builds and runs tests
# ============================================================================
test_everything_builds_and_tests_pass() {
    echo "TEST: Everything enabled builds and runs tests"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/MyApp"

    "$CONFIGURE" $BASE_OPTIONS \
        --answer name=MyApp \
        --answer features=openapi,websockets,vscode \
         "$OUTPUT_DIR" \
        </dev/null 2>&1

    cd "$OUTPUT_DIR"
    swift test
    assert_exit_code $? 0 "exits successfully"

    teardown
}

# ============================================================================
# Run all tests
# ============================================================================
echo "========================================"
echo "configure.sh test suite"
echo "========================================"
echo ""

test_all_flags
echo ""
test_lambda_type
echo ""
test_minimal_flags
echo ""
test_openapi_only
echo ""
test_websockets_only
echo ""
test_invalid_package_name
echo ""
test_unknown_option
echo ""
test_generated_ci_yml
echo ""
test_interactive_all_defaults
echo ""
test_interactive_custom_values
echo ""
test_everything_builds_and_tests_pass

echo ""
echo "========================================"
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
