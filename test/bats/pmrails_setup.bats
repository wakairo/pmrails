#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars

    PMRAILS_SYS_CONF="$BATS_TEST_TMPDIR/sys/config"
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/xdg"

    mkdir -p "$(dirname "$PMRAILS_SYS_CONF")" "$HOME" "$XDG_CONFIG_HOME"
    cd "$BATS_TEST_TMPDIR" || exit 1
}

@test "prepares a complete runtime configuration for entrypoint scripts" {
    enter_test_project_dir "sample-app"
    write_lines_to ".ruby-version" "ruby-3.3.7"
    write_lines_to ".pmrails/Dockerfile" "FROM ruby:3.3.7"

    pmrails_setup

    assert_equal "$PMRAILS_RUBY_VERSION" "3.3.7"
    assert_equal "$PMRAILS_IMAGE_REPO" "pmrails-sample_app"
    assert_equal "$PMRAILS_RUBY_VERSION_AT_NEW" "latest"
    assert_equal "$PMRAILS_PORTS" "127.0.0.1:3000:3000"
    assert_equal "$PMRAILS_PROJECT_NAME" "sample_app"
    assert_equal "$PMRAILS_DOCKERFILE" ".pmrails/Dockerfile"
    assert_equal "$PMRAILS_BUILD_CONTEXT" ".pmrails/build_context"
    assert_equal "$PMRAILS_COMPOSE_FILE" ".pmrails/compose.yaml"
}

@test "caller-exported PMRAILS variables override config and defaults even when exported empty" {
    enter_test_project_dir "env-wins"
    write_lines_to "$XDG_CONFIG_HOME/pmrails/config" \
        'PMRAILS_PORTS="9999:9999"' \
        'PMRAILS_RUBY_VERSION_AT_NEW="3.3.3"'

    export PMRAILS_PORTS=""
    export PMRAILS_RUBY_VERSION_AT_NEW="4.4.4"

    pmrails_setup

    assert_equal "$PMRAILS_PORTS" ""
    assert_equal "$PMRAILS_RUBY_VERSION_AT_NEW" "4.4.4"

    assert_equal "$PMRAILS_RUBY_VERSION" "latest"
    assert_equal "$PMRAILS_IMAGE_REPO" "ruby"
    assert_equal "$PMRAILS_PROJECT_NAME" "env_wins"
    assert_equal "$PMRAILS_DOCKERFILE" ".pmrails/Dockerfile"
    assert_equal "$PMRAILS_BUILD_CONTEXT" ".pmrails/build_context"
    assert_equal "$PMRAILS_COMPOSE_FILE" ".pmrails/compose.yaml"
}

@test "config values participate in setup before dynamic defaults fill the remaining runtime values" {
    enter_test_project_dir "configured-df"
    write_lines_to ".pmrails/config" \
        'PMRAILS_DOCKERFILE="containers/dev.Dockerfile"' \
        'PMRAILS_BUILD_CONTEXT="containers/build_context"'
    write_lines_to "containers/dev.Dockerfile" "FROM ruby:latest"

    pmrails_setup

    assert_equal "$PMRAILS_RUBY_VERSION" "latest"
    assert_equal "$PMRAILS_DOCKERFILE" "containers/dev.Dockerfile"
    assert_equal "$PMRAILS_BUILD_CONTEXT" "containers/build_context"
    assert_equal "$PMRAILS_PROJECT_NAME" "configured_df"
    assert_equal "$PMRAILS_IMAGE_REPO" "pmrails-configured_df"
    assert_equal "$PMRAILS_COMPOSE_FILE" ".pmrails/compose.yaml"
    assert_equal "$PMRAILS_PORTS" "127.0.0.1:3000:3000"
    assert_equal "$PMRAILS_RUBY_VERSION_AT_NEW" "latest"
}

@test ":AUTO in project config resets earlier config values to automatic defaults" {
    enter_test_project_dir "auto-config"
    write_lines_to ".ruby-version" "ruby-3.3.7"
    write_lines_to "$XDG_CONFIG_HOME/pmrails/config" \
        'PMRAILS_RUBY_VERSION="9.9.9"' \
        'PMRAILS_PORTS="9999:9999"'
    write_lines_to ".pmrails/config" \
        'PMRAILS_RUBY_VERSION=":AUTO"' \
        'PMRAILS_PORTS=":AUTO"'

    pmrails_setup

    assert_equal "$PMRAILS_RUBY_VERSION" "3.3.7"
    assert_equal "$PMRAILS_PORTS" "127.0.0.1:3000:3000"
}

@test ":AUTO in caller-exported variables resets config values to automatic defaults" {
    enter_test_project_dir "auto-env"
    write_lines_to ".ruby-version" "ruby-3.3.7"
    write_lines_to ".pmrails/config" \
        'PMRAILS_RUBY_VERSION="9.9.9"' \
        'PMRAILS_PORTS="9999:9999"'
    export PMRAILS_RUBY_VERSION=":AUTO"
    export PMRAILS_PORTS=":AUTO"

    pmrails_setup

    assert_equal "$PMRAILS_RUBY_VERSION" "3.3.7"
    assert_equal "$PMRAILS_PORTS" "127.0.0.1:3000:3000"
}
