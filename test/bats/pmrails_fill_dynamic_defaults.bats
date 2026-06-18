#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
    cd "$BATS_TEST_TMPDIR" || exit 1
}

@test "fills all default values when neither .ruby-version nor a Dockerfile exists" {
    enter_test_project_dir "plain_project"

    pmrails_fill_dynamic_defaults

    assert_equal "$PMRAILS_RUBY_VERSION" "latest"
    assert_equal "$PMRAILS_DOCKERFILE" ".pmrails/Dockerfile"
    assert_equal "$PMRAILS_PROJECT_NAME" "plain_project"
    assert_equal "$PMRAILS_IMAGE_REPO" "ruby"
    assert_equal "$PMRAILS_RUBY_VERSION_AT_NEW" "latest"
    assert_equal "$PMRAILS_PORTS" "3000:3000"
    assert_equal "$PMRAILS_COMPOSE_FILE" ".pmrails/compose.yaml"
}

@test "derives project name before image repo so the default Dockerfile path produces a project-specific image" {
    enter_test_project_dir "!!sample-app__development??"
    write_lines_to ".ruby-version" "ruby-3.3.7"
    write_lines_to ".pmrails/Dockerfile" "FROM ruby:3.3.7"

    pmrails_fill_dynamic_defaults

    assert_equal "$PMRAILS_RUBY_VERSION" "3.3.7"
    assert_equal "$PMRAILS_DOCKERFILE" ".pmrails/Dockerfile"
    assert_equal "$PMRAILS_PROJECT_NAME" "sample_app_devel"
    assert_equal "$PMRAILS_IMAGE_REPO" "pmrails-sample_app_devel"
    assert_equal "$PMRAILS_RUBY_VERSION_AT_NEW" "latest"
    assert_equal "$PMRAILS_PORTS" "3000:3000"
    assert_equal "$PMRAILS_COMPOSE_FILE" ".pmrails/compose.yaml"
}

@test "does not overwrite already-resolved values and stays stable across a second call after filesystem changes" {
    enter_test_project_dir "project_for_idempotency"
    write_lines_to ".ruby-version" "3.2.1"
    write_lines_to ".pmrails/Dockerfile" "FROM ruby:3.2.1"

    PMRAILS_RUBY_VERSION="8.8.8"
    PMRAILS_DOCKERFILE="custom/Dockerfile"
    PMRAILS_PROJECT_NAME="explicit_project"
    PMRAILS_IMAGE_REPO="custom/repo"
    PMRAILS_RUBY_VERSION_AT_NEW="7.7.7"
    PMRAILS_COMPOSE_FILE="custom/compose.yaml"
    PMRAILS_PORTS="5000:5001"
    pmrails_fill_dynamic_defaults

    assert_equal "$PMRAILS_RUBY_VERSION" "8.8.8"
    assert_equal "$PMRAILS_DOCKERFILE" "custom/Dockerfile"
    assert_equal "$PMRAILS_PROJECT_NAME" "explicit_project"
    assert_equal "$PMRAILS_IMAGE_REPO" "custom/repo"
    assert_equal "$PMRAILS_RUBY_VERSION_AT_NEW" "7.7.7"
    assert_equal "$PMRAILS_PORTS" "5000:5001"
    assert_equal "$PMRAILS_COMPOSE_FILE" "custom/compose.yaml"

    rm -f .ruby-version .pmrails/Dockerfile
    write_lines_to ".ruby-version" "not-a-version"
    pmrails_fill_dynamic_defaults

    assert_equal "$PMRAILS_RUBY_VERSION" "8.8.8"
    assert_equal "$PMRAILS_DOCKERFILE" "custom/Dockerfile"
    assert_equal "$PMRAILS_PROJECT_NAME" "explicit_project"
    assert_equal "$PMRAILS_IMAGE_REPO" "custom/repo"
    assert_equal "$PMRAILS_RUBY_VERSION_AT_NEW" "7.7.7"
    assert_equal "$PMRAILS_PORTS" "5000:5001"
    assert_equal "$PMRAILS_COMPOSE_FILE" "custom/compose.yaml"
}

@test "propagates ruby version parse failures instead of silently filling later defaults" {
    enter_test_project_dir "broken_ruby_version"
    write_lines_to ".ruby-version" "no-version-here"

    run pmrails_fill_dynamic_defaults

    assert_failure 3
    assert_output --partial 'pmrails: error: could not parse a version'
}

@test "lowercases PMRAILS_PROJECT_NAME" {
    enter_test_project_dir "Sample-App_DEV"

    pmrails_fill_dynamic_defaults

    assert_equal "$PMRAILS_PROJECT_NAME" "sample_app_dev"
}

@test "sanitizes PMRAILS_PROJECT_NAME by stripping trailing non-alphanumeric characters" {
    enter_test_project_dir "._0_-.2345678901234-------"

    pmrails_fill_dynamic_defaults

    assert_equal "$PMRAILS_PROJECT_NAME" "0_2345678901234"
}

@test "exits with non-zero status when PWD is unset" {
    unset PWD
    run pmrails_fill_dynamic_defaults
    assert_failure 2
    assert_output --partial 'pmrails: error: PWD can not be unset nor empty'
}

@test "exits with non-zero status when PWD is an empty string" {
    PWD=""
    run pmrails_fill_dynamic_defaults
    assert_failure 2
    assert_output --partial 'pmrails: error: PWD can not be unset nor empty'
}

@test "exits with non-zero status when the sanitized directory name becomes empty" {
    enter_test_project_dir "!!!___---"
    run pmrails_fill_dynamic_defaults
    assert_failure 2
    assert_output --partial 'pmrails: error: PMRAILS_PROJECT_NAME can not be empty'
}
