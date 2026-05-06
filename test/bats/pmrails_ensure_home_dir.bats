#!/usr/bin/env bats

load test_helper.bash

setup() {
    load_pmrails_library
    cd "$BATS_TEST_TMPDIR" || exit 1
}

@test "creates the in-project home directory and succeeds when it already exists" {
    pmrails_ensure_home_dir
    assert [ -d "$_PMRAILS_VAR_DIR/home" ]

    pmrails_ensure_home_dir
    assert [ -d "$_PMRAILS_VAR_DIR/home" ]
}
