#!/usr/bin/env bats

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
}

@test "expands a major Rails version to a pessimistic requirement" {
    run pmrails_expand_rails_version_requirement "8"

    assert_success
    assert_output "~> 8.0"
}

@test "expands a major-minor Rails version to a pessimistic requirement" {
    run pmrails_expand_rails_version_requirement "8.1"

    assert_success
    assert_output "~> 8.1.0"
}

@test "expands a major-minor-patch Rails version to a pessimistic requirement" {
    run pmrails_expand_rails_version_requirement "8.1.3"

    assert_success
    assert_output "~> 8.1.3.0"
}

@test "preserves an explicit equality requirement" {
    run pmrails_expand_rails_version_requirement "= 8.1"

    assert_success
    assert_output "= 8.1"
}

@test "preserves an existing pessimistic requirement" {
    run pmrails_expand_rails_version_requirement "~> 8.1.0"

    assert_success
    assert_output "~> 8.1.0"
}

@test "preserves a comparison requirement" {
    run pmrails_expand_rails_version_requirement ">= 8.1"

    assert_success
    assert_output ">= 8.1"
}

@test "preserves a prerelease-like version" {
    run pmrails_expand_rails_version_requirement "8.1.rc1"

    assert_success
    assert_output "8.1.rc1"
}

@test "preserves a malformed dotted value" {
    run pmrails_expand_rails_version_requirement "8..1"

    assert_success
    assert_output "8..1"
}
