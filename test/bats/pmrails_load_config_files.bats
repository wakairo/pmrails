#!/usr/bin/env bats
# shellcheck disable=SC2016

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
    PMRAILS_SYS_CONF="$BATS_TEST_TMPDIR/sys/conf"
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/xdg"
    mkdir -p "$(dirname "$PMRAILS_SYS_CONF")" "$HOME" "$XDG_CONFIG_HOME" "$BATS_TEST_TMPDIR/project/.pmrails"
    cd "$BATS_TEST_TMPDIR/project" || exit 1
}

@test "loads system, user, project, and local config files in that order" {
    write_lines_to "$PMRAILS_SYS_CONF" \
        'PMRAILS_TEST_LOAD_TRACE="sys"' \
        'PMRAILS_TEST_LOAD_WINNER="sys"'
    write_lines_to "$XDG_CONFIG_HOME/pmrails/config" \
        'PMRAILS_TEST_LOAD_TRACE="${PMRAILS_TEST_LOAD_TRACE}>user"' \
        'PMRAILS_TEST_LOAD_WINNER="user"'
    write_lines_to ".pmrails/config" \
        'PMRAILS_TEST_LOAD_TRACE="${PMRAILS_TEST_LOAD_TRACE}>project"' \
        'PMRAILS_TEST_LOAD_WINNER="project"'
    write_lines_to ".pmrails/config.local" \
        'PMRAILS_TEST_LOAD_TRACE="${PMRAILS_TEST_LOAD_TRACE}>local"' \
        'PMRAILS_TEST_LOAD_WINNER="local"'

    pmrails_load_config_files

    assert_equal "$PMRAILS_TEST_LOAD_TRACE" "sys>user>project>local"
    assert_equal "$PMRAILS_TEST_LOAD_WINNER" "local"
}

@test "prefers XDG_CONFIG_HOME over HOME/.config for the user config path" {
    write_lines_to "$HOME/.config/pmrails/config" \
        'PMRAILS_TEST_USER_SOURCE="home-fallback"'
    write_lines_to "$XDG_CONFIG_HOME/pmrails/config" \
        'PMRAILS_TEST_USER_SOURCE="xdg"'

    pmrails_load_config_files

    assert_equal "$PMRAILS_TEST_USER_SOURCE" "xdg"
}

@test "falls back to HOME/.config when XDG_CONFIG_HOME is unset" {
    unset XDG_CONFIG_HOME
    write_lines_to "$HOME/.config/pmrails/config" \
        'PMRAILS_TEST_HOME_FALLBACK="loaded-from-home"'

    pmrails_load_config_files

    assert_equal "$PMRAILS_TEST_HOME_FALLBACK" "loaded-from-home"
}

@test "does not require HOME when XDG_CONFIG_HOME is already set" {
    unset HOME
    write_lines_to "$XDG_CONFIG_HOME/pmrails/config" \
        'PMRAILS_TEST_USER_SOURCE="xdg-only"'

    pmrails_load_config_files

    assert_equal "$PMRAILS_TEST_USER_SOURCE" "xdg-only"
}

@test "skips unreadable config files without error" {
    [ "$(id -u)" -ne 0 ] || skip "as root, cannot test file permissions"

    write_lines_to ".pmrails/config" \
        'PMRAILS_TEST_SURVIVOR="project"'
    write_lines_to ".pmrails/config.local" \
        'PMRAILS_TEST_SURVIVOR="local"'
    chmod 000 ".pmrails/config.local"

    pmrails_load_config_files

    assert_equal "$PMRAILS_TEST_SURVIVOR" "project"

    chmod 644 ".pmrails/config.local"
}

@test "succeeds when no config files exist" {
    pmrails_load_config_files
}

@test "succeeds when both XDG_CONFIG_HOME and HOME are unset" {
    unset XDG_CONFIG_HOME
    unset HOME
    pmrails_load_config_files
}
