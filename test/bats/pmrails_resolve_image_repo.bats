#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2034

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
    PMRAILS_PROJECT_NAME="prj_set_at_setup"
    PMRAILS_DOCKERFILE="${BATS_TEST_TMPDIR}/Dockerfile"
    rm -f "$PMRAILS_DOCKERFILE"
}

@test "preserves PMRAILS_IMAGE_REPO when it is already set" {
    PMRAILS_IMAGE_REPO="myrepo"
    pmrails_resolve_image_repo
    assert_equal "$PMRAILS_IMAGE_REPO" "myrepo"

    touch "$PMRAILS_DOCKERFILE"
    pmrails_resolve_image_repo
    assert_equal "$PMRAILS_IMAGE_REPO" "myrepo"
}

@test "resolves to project-specific image when PMRAILS_IMAGE_REPO is unset and Dockerfile exists" {
    touch "$PMRAILS_DOCKERFILE"
    PMRAILS_PROJECT_NAME="myprj"
    pmrails_resolve_image_repo
    assert_equal "$PMRAILS_IMAGE_REPO" "pmrails-myprj"
}

@test "exits with an unbound-variable error when PMRAILS_PROJECT_NAME is unset" {
    unset PMRAILS_PROJECT_NAME
    touch "$PMRAILS_DOCKERFILE"
    run pmrails_resolve_image_repo
    assert_failure
    assert_output --regexp "PMRAILS_PROJECT_NAME.*unbound variable"
}

@test "sets PMRAILS_IMAGE_REPO to 'pmrails-' when PMRAILS_PROJECT_NAME is empty and Dockerfile exists" {
    touch "$PMRAILS_DOCKERFILE"
    PMRAILS_PROJECT_NAME=""
    pmrails_resolve_image_repo
    assert_equal "$PMRAILS_IMAGE_REPO" "pmrails-"
}

@test "falls back to 'ruby' when no Dockerfile exists" {
    pmrails_resolve_image_repo
    assert_equal "$PMRAILS_IMAGE_REPO" "ruby"
}

@test "treats an empty PMRAILS_IMAGE_REPO as unset and falls back to 'ruby'" {
    PMRAILS_IMAGE_REPO=""
    pmrails_resolve_image_repo
    assert_equal "$PMRAILS_IMAGE_REPO" "ruby"
}

@test "treats an empty PMRAILS_DOCKERFILE as a non-existent file" {
    PMRAILS_PROJECT_NAME="x"
    PMRAILS_DOCKERFILE=""
    pmrails_resolve_image_repo
    assert_equal "$PMRAILS_IMAGE_REPO" "ruby"
}

@test "exits with an unbound-variable error when PMRAILS_DOCKERFILE is unset" {
    unset PMRAILS_DOCKERFILE
    run pmrails_resolve_image_repo
    assert_failure
    assert_output --regexp "PMRAILS_DOCKERFILE.*unbound variable"
}
