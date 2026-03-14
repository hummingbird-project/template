#!/usr/bin/env bash
##===----------------------------------------------------------------------===##
##
## Tests for configure.sh non-interactive flag support
##
##===----------------------------------------------------------------------===##

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TEMPLATE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
CONFIGURE="$TEMPLATE_DIR/configure.sh"

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
    local OUTPUT_DIR="$TEST_TMPDIR/myapp"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "MyApp" \
        --executable-name "MyServer" \
        --openapi \
        --vscode-snippets \
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
# Test: Fully non-interactive with --lambda flag
# ============================================================================
test_lambda_flag() {
    echo "TEST: Lambda flag (fully non-interactive)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/lambdaapp"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "LambdaApp" \
        --lambda \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_exists "$OUTPUT_DIR/Package.swift" "Package.swift is created"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "LambdaApp" "Package.swift contains package name"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Package.swift contains Lambda dependency"

    teardown
}

# ============================================================================
# Test: --lambda overrides --executable-name
# ============================================================================
test_lambda_overrides_executable() {
    echo "TEST: --lambda ignores --executable-name"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/lambdaoverride"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "LambdaOverride" \
        --lambda \
        --executable-name "CustomExe" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_not_contains "$OUTPUT_DIR/Package.swift" "CustomExe" "executable name flag is ignored when --lambda is set"

    teardown
}

# ============================================================================
# Test: Minimal flags — booleans default to "no"
# ============================================================================
test_minimal_flags() {
    echo "TEST: Minimal flags (only --package-name, booleans default to no)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/minimalapp"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "MinimalApp" \
        --executable-name "MinExe" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_exists "$OUTPUT_DIR/Package.swift" "Package.swift is created"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "MinimalApp" "Package.swift contains package name"
    assert_file_not_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda is not enabled"
    assert_dir_not_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI directory not created"

    teardown
}

# ============================================================================
# Test: Only --package-name — executable defaults to "App"
# ============================================================================
test_package_name_only() {
    echo "TEST: Only --package-name (executable defaults to App)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/pkgonly"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "PkgOnly" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "PkgOnly" "Package.swift contains package name"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "App" "executable defaults to App"
    assert_file_not_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda defaults to off"
    assert_dir_not_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI defaults to off"

    teardown
}

# ============================================================================
# Test: Only --openapi — package name defaults to folder basename
# ============================================================================
test_openapi_only() {
    echo "TEST: Only --openapi (package name defaults to folder basename)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/my_project"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --openapi \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "my_project" "package name defaults to cleaned folder basename"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "App" "executable defaults to App"
    assert_dir_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI directory created"
    assert_file_not_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda defaults to off"

    teardown
}

# ============================================================================
# Test: Only --lambda — package name defaults to folder basename
# ============================================================================
test_lambda_only() {
    echo "TEST: Only --lambda (package name defaults to folder basename)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/lambda_project"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --lambda \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "lambda_project" "package name defaults to cleaned folder basename"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda is enabled"

    teardown
}

# ============================================================================
# Test: Invalid package name via flag
# ============================================================================
test_invalid_package_name() {
    echo "TEST: Invalid package name via flag"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/badname"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "Bad Name!" \
        --executable-name "App" \
        </dev/null 2>&1

    assert_exit_code $? 1 "exits with error for invalid package name"

    teardown
}

# ============================================================================
# Test: Invalid executable name via flag
# ============================================================================
test_invalid_executable_name() {
    echo "TEST: Invalid executable name via flag"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/badexe"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "GoodName" \
        --executable-name "Bad Exe!" \
        </dev/null 2>&1

    assert_exit_code $? 1 "exits with error for invalid executable name"

    teardown
}

# ============================================================================
# Test: Unknown flag produces error
# ============================================================================
test_unknown_flag() {
    echo "TEST: Unknown flag produces error"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/unknownflag"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "TestApp" \
        --bogus-flag \
        </dev/null 2>&1

    assert_exit_code $? 1 "exits with error for unknown flag"

    teardown
}

# ============================================================================
# Test: Flags can appear before or after positional arg
# ============================================================================
test_flags_after_positional() {
    echo "TEST: Flags after positional argument"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/flagsafter"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "FlagsAfter" \
        --executable-name "App" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "FlagsAfter" "Package.swift contains package name"

    teardown
}

test_flags_before_positional() {
    echo "TEST: Flags before positional argument"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/flagsbefore"

    "$CONFIGURE" \
        --defaults \
        --package-name "FlagsBefore" \
        --executable-name "App" \
        "$OUTPUT_DIR" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "FlagsBefore" "Package.swift contains package name"

    teardown
}

# ============================================================================
# Test: Generated project contains valid ci.yml
# ============================================================================
test_generated_ci_yml() {
    echo "TEST: Generated project contains valid ci.yml"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/citest"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --package-name "CiTest" \
        --executable-name "App" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_exists "$OUTPUT_DIR/.github/workflows/ci.yml" "ci.yml exists in generated project"
    assert_file_not_contains "$OUTPUT_DIR/.github/workflows/ci.yml" "{{hb" "ci.yml does not contain mustache syntax"

    teardown
}

# ============================================================================
# Test: --defaults only (all defaults, no prompts)
# ============================================================================
test_defaults_only() {
    echo "TEST: --defaults only (all defaults, no prompts)"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/defaultsonly"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_exists "$OUTPUT_DIR/Package.swift" "Package.swift is created"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "defaultsonly" "package name defaults to folder basename"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "App" "executable defaults to App"
    assert_file_not_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda defaults to off"
    assert_dir_not_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI defaults to off"

    teardown
}

# ============================================================================
# Test: --defaults with some flags
# ============================================================================
test_defaults_with_some_flags() {
    echo "TEST: --defaults with some flags"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/defaultsflags"

    "$CONFIGURE" "$OUTPUT_DIR" \
        --defaults \
        --openapi \
        --package-name "CoolAPI" \
        </dev/null 2>&1

    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "CoolAPI" "package name from flag"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "App" "executable defaults to App"
    assert_dir_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI enabled from flag"
    assert_file_not_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda defaults to off"

    teardown
}

# ============================================================================
# Test: --help prints usage and exits 0
# ============================================================================
test_help() {
    echo "TEST: --help prints usage and exits 0"
    setup

    local OUTPUT
    OUTPUT=$("$CONFIGURE" --help 2>&1)
    assert_exit_code $? 0 "--help exits with code 0"

    if echo "$OUTPUT" | grep -q "\-\-defaults"; then
        echo "  PASS: --help output mentions --defaults"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL: --help output should mention --defaults"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    if echo "$OUTPUT" | grep -q "\-\-package-name"; then
        echo "  PASS: --help output mentions --package-name"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL: --help output should mention --package-name"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    if echo "$OUTPUT" | grep -q "\-\-lambda"; then
        echo "  PASS: --help output mentions --lambda"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL: --help output should mention --lambda"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

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
        spawn $CONFIGURE $OUTPUT_DIR
        expect \"Enter your Swift package name:\"
        send \"\r\"
        expect \"Do you want to build an AWS Lambda function?\"
        send \"\r\"
        expect \"Enter your executable name:\"
        send \"\r\"
        expect \"Do you want to use the OpenAPI generator?\"
        send \"\r\"
        expect \"Include Visual Studio Code snippets:\"
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
        spawn $CONFIGURE $OUTPUT_DIR
        expect \"Enter your Swift package name:\"
        send \"CustomPkg\r\"
        expect \"Do you want to build an AWS Lambda function?\"
        send \"n\r\"
        expect \"Enter your executable name:\"
        send \"MyExe\r\"
        expect \"Do you want to use the OpenAPI generator?\"
        send \"y\r\"
        expect \"Include Visual Studio Code snippets:\"
        send \"y\r\"
        expect eof
        catch wait result
        exit [lindex \$result 3]
    "
    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "CustomPkg" "package name is CustomPkg"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "MyExe" "executable name is MyExe"
    assert_dir_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI directory created"

    teardown
}

# ============================================================================
# Test: Flag without --defaults — flag's prompt is skipped, others appear
# ============================================================================
test_interactive_with_openapi_flag() {
    echo "TEST: --openapi without --defaults — skips openapi prompt, prompts for rest"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/interactive_flag"

    run_expect "
        set timeout 30
        spawn $CONFIGURE $OUTPUT_DIR --openapi
        expect \"Enter your Swift package name:\"
        send \"FlagTest\r\"
        expect \"Do you want to build an AWS Lambda function?\"
        send \"n\r\"
        expect \"Enter your executable name:\"
        send \"App\r\"
        # OpenAPI prompt should NOT appear — it was set by flag
        expect \"Include Visual Studio Code snippets:\"
        send \"n\r\"
        expect eof
        catch wait result
        exit [lindex \$result 3]
    "
    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "FlagTest" "package name from interactive input"
    assert_dir_exists "$OUTPUT_DIR/Sources/AppAPI" "OpenAPI enabled from flag"

    teardown
}

# ============================================================================
# Test: --lambda flag without --defaults — skips lambda + exe prompts
# ============================================================================
test_interactive_with_lambda_flag() {
    echo "TEST: --lambda without --defaults — skips lambda and executable prompts"
    setup
    local OUTPUT_DIR="$TEST_TMPDIR/interactive_lambda"

    run_expect "
        set timeout 30
        spawn $CONFIGURE $OUTPUT_DIR --lambda
        expect \"Enter your Swift package name:\"
        send \"LambdaInteractive\r\"
        # Lambda prompt should NOT appear — set by flag
        # Executable prompt should NOT appear — forced by lambda
        expect \"Do you want to use the OpenAPI generator?\"
        send \"n\r\"
        expect \"Include Visual Studio Code snippets:\"
        send \"n\r\"
        expect eof
        catch wait result
        exit [lindex \$result 3]
    "
    assert_exit_code $? 0 "exits successfully"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "LambdaInteractive" "package name from interactive input"
    assert_file_contains "$OUTPUT_DIR/Package.swift" "hummingbird-lambda" "Lambda enabled from flag"

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
test_lambda_flag
echo ""
test_lambda_overrides_executable
echo ""
test_minimal_flags
echo ""
test_package_name_only
echo ""
test_openapi_only
echo ""
test_lambda_only
echo ""
test_invalid_package_name
echo ""
test_invalid_executable_name
echo ""
test_unknown_flag
echo ""
test_flags_after_positional
echo ""
test_flags_before_positional
echo ""
test_generated_ci_yml
echo ""
test_defaults_only
echo ""
test_defaults_with_some_flags
echo ""
test_help
echo ""
test_interactive_all_defaults
echo ""
test_interactive_custom_values
echo ""
test_interactive_with_openapi_flag
echo ""
test_interactive_with_lambda_flag

echo ""
echo "========================================"
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
