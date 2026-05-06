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
    assert_equal "$PMRAILS_PORTS" "3000:3000"
    assert_equal "$PMRAILS_PROJECT_NAME" "sample_app"
    assert_equal "$PMRAILS_DOCKERFILE" ".pmrails/Dockerfile"
    assert_equal "$PMRAILS_COMPOSE_FILE" ".pmrails/compose.yaml"
}

@test "caller-exported PMRAILS variables override config and static defaults even when exported empty" {
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
    assert_equal "$PMRAILS_COMPOSE_FILE" ".pmrails/compose.yaml"
}

@test "config values participate in setup before dynamic defaults fill the remaining runtime values" {
    enter_test_project_dir "configured-df"
    write_lines_to ".pmrails/config" \
        'PMRAILS_DOCKERFILE="containers/dev.Dockerfile"'
    write_lines_to "containers/dev.Dockerfile" "FROM ruby:latest"

    pmrails_setup

    assert_equal "$PMRAILS_RUBY_VERSION" "latest"
    assert_equal "$PMRAILS_DOCKERFILE" "containers/dev.Dockerfile"
    assert_equal "$PMRAILS_PROJECT_NAME" "configured_df"
    assert_equal "$PMRAILS_IMAGE_REPO" "pmrails-configured_df"
    assert_equal "$PMRAILS_COMPOSE_FILE" ".pmrails/compose.yaml"
    assert_equal "$PMRAILS_PORTS" "3000:3000"
    assert_equal "$PMRAILS_RUBY_VERSION_AT_NEW" "latest"
}
