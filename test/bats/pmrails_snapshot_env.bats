#!/usr/bin/env bats
# shellcheck disable=SC2034

load test_helper.bash

snapshot_has_line() {
    printf '%s\n' "$_PMRAILS_ENV_SNAPSHOT" | grep -Fx -- "$1"
}

snapshot_lacks_text() {
    ! printf '%s\n' "$_PMRAILS_ENV_SNAPSHOT" | grep -Fq -- "$1"
}

setup() {
    load_pmrails_library
    unset_pmrails_vars
    unset _PMRAILS_ENV_SNAPSHOT
    cd "$BATS_TEST_TMPDIR" || exit 1
}

@test "produces an empty snapshot when no PMRAILS_ environment variables are exported" {
    pmrails_snapshot_env

    assert_equal "$_PMRAILS_ENV_SNAPSHOT" ""
}

@test "captures only exported PMRAILS_ variables" {
    export PMRAILS_EXPORTED="visible"
    PMRAILS_SHELL_ONLY="hidden"
    export OTHER_VARIABLE="other"
    export _PMRAILS_INTERNAL="internal"

    pmrails_snapshot_env

    snapshot_has_line "export PMRAILS_EXPORTED='visible'"
    snapshot_lacks_text "PMRAILS_SHELL_ONLY="
    snapshot_lacks_text "OTHER_VARIABLE="
    snapshot_lacks_text "_PMRAILS_INTERNAL="
}

@test "captures all exported PMRAILS_* variables, not just the first one" {
    export PMRAILS_TEST_A="one"
    export PMRAILS_TEST_B="two"
    pmrails_snapshot_env
    snapshot_has_line "export PMRAILS_TEST_A='one'"
    snapshot_has_line "export PMRAILS_TEST_B='two'"
}

@test "restores an exported empty value instead of keeping a later override" {
    export PMRAILS_EMPTY=""

    pmrails_snapshot_env
    PMRAILS_EMPTY="from-config"
    pmrails_restore_env

    assert_equal "$PMRAILS_EMPTY" ""
    assert_equal "${_PMRAILS_ENV_SNAPSHOT+set}" ""
}

@test "restores shell metacharacters and single quotes literally without executing them" {
    local dollar_marker="${BATS_TEST_TMPDIR}/created-by-dollar-substitution"
    local backtick_marker="${BATS_TEST_TMPDIR}/created-by-backticks"
    local original_value="\$(touch ${dollar_marker}) \`touch ${backtick_marker}\` ; keep * literal and 'quoted' text"

    export PMRAILS_COMPLEX="$original_value"

    pmrails_snapshot_env
    PMRAILS_COMPLEX="mutated"
    pmrails_restore_env

    assert_equal "$PMRAILS_COMPLEX" "$original_value"
    refute [ -e "$dollar_marker" ]
    refute [ -e "$backtick_marker" ]
}

@test "restores variables with export attribute even if they were unset in between" {
    export PMRAILS_TARGET="value"

    pmrails_snapshot_env

    unset PMRAILS_TARGET
    pmrails_restore_env

    run sh -c 'printf "%s" "$PMRAILS_TARGET"'
    assert_equal "$output" "value"
}

@test "captures and restores values containing literal newlines" {
    export PMRAILS_MULTILINE="first line
second line"

    pmrails_snapshot_env
    PMRAILS_MULTILINE="overridden"
    pmrails_restore_env

    assert_equal "$PMRAILS_MULTILINE" "first line
second line"
}
