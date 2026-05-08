#!/usr/bin/env bats
# shellcheck disable=SC2034

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
}

@test "produces an empty string when PMRAILS_PORTS is unset" {
    pmrails_build_ports_args
    assert_equal "$_PMRAILS_PORTS_ARGS" ""
}

@test "produces an empty string when PMRAILS_PORTS is an empty string" {
    PMRAILS_PORTS=""
    pmrails_build_ports_args
    assert_equal "$_PMRAILS_PORTS_ARGS" ""
}

@test "produces a single -p argument from one port mapping" {
    PMRAILS_PORTS="5000:5001"
    pmrails_build_ports_args
    assert_equal "$_PMRAILS_PORTS_ARGS" "-p 5000:5001"
}

@test "produces two -p arguments from two port mappings" {
    PMRAILS_PORTS="7000 5000:5001"
    pmrails_build_ports_args
    assert_equal "$_PMRAILS_PORTS_ARGS" "-p 7000 -p 5000:5001"
}

@test "produces three -p arguments from three port mappings" {
    PMRAILS_PORTS="7000 5000:5001 1234-1236:2234-2236"
    pmrails_build_ports_args
    assert_equal "$_PMRAILS_PORTS_ARGS" "-p 7000 -p 5000:5001 -p 1234-1236:2234-2236"
}

@test "ignores extra whitespace between port mappings" {
    PMRAILS_PORTS="  7000   5000:5001  1234-1236:2234-2236    "
    pmrails_build_ports_args
    assert_equal "$_PMRAILS_PORTS_ARGS" "-p 7000 -p 5000:5001 -p 1234-1236:2234-2236"
}

@test "treats glob characters in port values as literals without altering the caller's globbing" {
    cd "$BATS_TEST_TMPDIR" || exit 1
    touch "port_dummy_1" "port_dummy_2"

    PMRAILS_PORTS="* port_dummy_?"
    pmrails_build_ports_args

    assert_equal "$_PMRAILS_PORTS_ARGS" "-p * -p port_dummy_?"

    set -- port_dummy_*
    assert_equal "$*" "port_dummy_1 port_dummy_2"
}

@test "produces an empty string when PMRAILS_PORTS is whitespace only" {
    PMRAILS_PORTS="   "
    pmrails_build_ports_args
    assert_equal "$_PMRAILS_PORTS_ARGS" ""
}
