#!/usr/bin/env bats
# shellcheck disable=SC2034

load test_helper.bash

readonly _SERVICES_PLACEHOLDER='services: {}'

read_compose_override() {
    cat "$_PMRAILS_COMPOSE_OVERRIDE_FILE"
}

setup() {
    load_pmrails_library
    unset_pmrails_vars
    cd "$BATS_TEST_TMPDIR" || exit 1
    mkdir -p "$(dirname "$_PMRAILS_COMPOSE_OVERRIDE_FILE")"
}

@test "writes a minimal placeholder when PMRAILS_PORTS is unset" {
    pmrails_generate_compose_override

    assert [ -f "$_PMRAILS_COMPOSE_OVERRIDE_FILE" ]
    assert_equal "$(read_compose_override)" "$_SERVICES_PLACEHOLDER"
}

@test "writes a minimal placeholder when PMRAILS_PORTS is an empty string" {
    PMRAILS_PORTS=""

    pmrails_generate_compose_override

    assert_equal "$(read_compose_override)" "$_SERVICES_PLACEHOLDER"
}

@test "writes a minimal placeholder when PMRAILS_PORTS is whitespace only" {
    PMRAILS_PORTS="     "

    pmrails_generate_compose_override

    assert_equal "$(read_compose_override)" "services: {}"
}

@test "rewrites the whole file when the port configuration changes" {
    PMRAILS_PORTS="3000:3000 1234:1234"
    pmrails_generate_compose_override

    PMRAILS_PORTS=""
    pmrails_generate_compose_override
    assert_equal "$(read_compose_override)" "$_SERVICES_PLACEHOLDER"

    PMRAILS_PORTS="4000:4000"
    pmrails_generate_compose_override
    assert_equal "$(read_compose_override)" $'services:\n  rails-app:\n    ports:\n      - "4000:4000"'
}

@test "writes one quoted port entry per whitespace-separated token" {
    PMRAILS_PORTS="  7000   5000:5001  1234-1236:2234-2236    "

    pmrails_generate_compose_override

    assert_equal "$(read_compose_override)" $'services:\n  rails-app:\n    ports:\n      - "7000"\n      - "5000:5001"\n      - "1234-1236:2234-2236"'
}

@test "treats glob characters in port values as literals without altering the caller's globbing" {
    touch "port_dummy_1" "port_dummy_2"
    PMRAILS_PORTS="* port_dummy_?"

    pmrails_generate_compose_override

    assert_equal "$(read_compose_override)" $'services:\n  rails-app:\n    ports:\n      - "*"\n      - "port_dummy_?"'

    set -- port_dummy_*
    assert_equal "$*" "port_dummy_1 port_dummy_2"
}
