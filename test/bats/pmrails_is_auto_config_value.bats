#!/usr/bin/env bats

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
}

# Returning 0 distinguishes a returned status from the required exit status 1.
call_is_auto_config_value_and_succeed_on_return() {
    if pmrails_is_auto_config_value "$1"; then
        :
    fi

    return 0
}

@test "returns status 1 for a normal literal configuration value without exiting" {
    local status

    if pmrails_is_auto_config_value "literal"; then
        status=0
    else
        status=$?
    fi

    assert_equal "$status" "1"
}

@test "returns status 0 for :AUTO" {
    pmrails_is_auto_config_value ":AUTO"
}

@test "exits with status 1 for an unsupported reserved configuration value" {
    run call_is_auto_config_value_and_succeed_on_return ":RESET"

    assert_failure 1
    assert_output 'pmrails: error: unsupported reserved PMRAILS configuration value: ":RESET"'
}
