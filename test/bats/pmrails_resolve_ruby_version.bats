#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
    cd "$BATS_TEST_TMPDIR" || exit 1
    rm -f .ruby-version
}

@test "preserves PMRAILS_RUBY_VERSION when it is already set" {
    PMRAILS_RUBY_VERSION="3.2.1"
    pmrails_resolve_ruby_version
    assert_equal "$PMRAILS_RUBY_VERSION" "3.2.1"

    write_lines_to ".ruby-version" "4.3.2"
    pmrails_resolve_ruby_version
    assert_equal "$PMRAILS_RUBY_VERSION" "3.2.1"

    write_lines_to ".ruby-version" "not-a-version"
    pmrails_resolve_ruby_version
    assert_equal "$PMRAILS_RUBY_VERSION" "3.2.1"
}

@test "falls back to 'latest' when .ruby-version does not exist" {
    pmrails_resolve_ruby_version
    assert_equal "$PMRAILS_RUBY_VERSION" "latest"
}

@test "parses a plain major.minor.patch version from the first line of .ruby-version" {
    write_lines_to ".ruby-version" "4.3.2"
    pmrails_resolve_ruby_version
    assert_equal "$PMRAILS_RUBY_VERSION" "4.3.2"
}

@test "parses version from .ruby-version with leading non-numeric prefix" {
    write_lines_to ".ruby-version" "ruby-3.3.7"
    pmrails_resolve_ruby_version
    assert_equal "$PMRAILS_RUBY_VERSION" "3.3.7"
}

@test "parses version from .ruby-version ignoring trailing text" {
    write_lines_to ".ruby-version" "3.2.2-p0"
    pmrails_resolve_ruby_version
    assert_equal "$PMRAILS_RUBY_VERSION" "3.2.2"
}

@test "sets PMRAILS_RUBY_VERSION to 'latest' when it is an empty string" {
    PMRAILS_RUBY_VERSION=""
    pmrails_resolve_ruby_version
    assert_equal "$PMRAILS_RUBY_VERSION" "latest"
}

@test "reads only the first line of .ruby-version" {
    write_lines_to ".ruby-version" "3.4.0" "3.4.1"
    pmrails_resolve_ruby_version
    assert_equal "$PMRAILS_RUBY_VERSION" "3.4.0"
}

@test "exits with non-zero status when .ruby-version contains an invalid version" {
    write_lines_to ".ruby-version" "4.3"
    run pmrails_resolve_ruby_version
    assert_failure 3
    assert_output --partial 'pmrails: error: could not parse a version'
    assert_output --partial 'pmrails: .ruby-version first line: "4.3"'
}

@test "exits with non-zero status when .ruby-version is empty" {
    touch .ruby-version
    run pmrails_resolve_ruby_version
    assert_failure 3
    assert_output --partial 'pmrails: error: could not parse a version'
    assert_output --partial 'pmrails: .ruby-version first line: ""'
}
