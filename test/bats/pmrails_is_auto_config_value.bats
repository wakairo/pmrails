#!/usr/bin/env bats

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
}

@test "returns failure for a normal literal configuration value" {
    run pmrails_is_auto_config_value "literal"

    assert_failure 1
}

@test "returns success for :AUTO" {
    run pmrails_is_auto_config_value ":AUTO"

    assert_success
}

@test "rejects unsupported reserved configuration values" {
    run pmrails_is_auto_config_value ":RESET"

    assert_failure 3
    assert_output --partial 'pmrails: error: unsupported reserved PMRAILS configuration value'
}
