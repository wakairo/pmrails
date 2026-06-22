#!/usr/bin/env bats
# shellcheck disable=SC2034,SC2317

load test_helper.bash

install_podman_stub() {
    podman() {
        case "$1:$2" in
        image:exists)
            PMRAILS_TEST_IMAGE_LOOKUP_NAME="$3"
            return "${PMRAILS_TEST_IMAGE_EXISTS_STATUS}"
            ;;
        esac

        fail "unexpected podman call: $*"
    }
}

install_build_image_stub() {
    pmrails_build_image() {
        PMRAILS_TEST_BUILD_IMAGE_NAME="${_PMRAILS_IMAGE_NAME}"
        return "${PMRAILS_TEST_BUILD_IMAGE_STATUS}"
    }
}

setup() {
    load_pmrails_library
    unset_pmrails_vars

    PMRAILS_IMAGE_REPO="pmrails-sample_app"
    PMRAILS_RUBY_VERSION="3.3.7"
    PMRAILS_RUBY_VERSION_SUFFIX=""

    PMRAILS_TEST_IMAGE_EXISTS_STATUS=0
    PMRAILS_TEST_IMAGE_LOOKUP_NAME=""
    PMRAILS_TEST_BUILD_IMAGE_NAME=""
    PMRAILS_TEST_BUILD_IMAGE_STATUS=0

    install_podman_stub
    install_build_image_stub
}

@test "selects the upstream ruby image without image lookup or build" {
    PMRAILS_IMAGE_REPO="ruby"
    PMRAILS_RUBY_VERSION="3.2.2"

    pmrails_ensure_image

    assert_equal "$_PMRAILS_IMAGE_NAME" "ruby:3.2.2"
    assert_equal "$PMRAILS_TEST_IMAGE_LOOKUP_NAME" ""
    assert_equal "$PMRAILS_TEST_BUILD_IMAGE_NAME" ""
}

@test "reuses an existing project image" {
    PMRAILS_TEST_IMAGE_EXISTS_STATUS=0

    pmrails_ensure_image

    assert_equal "$_PMRAILS_IMAGE_NAME" "pmrails-sample_app:3.3.7"
    assert_equal "$PMRAILS_TEST_IMAGE_LOOKUP_NAME" "pmrails-sample_app:3.3.7"
    assert_equal "$PMRAILS_TEST_BUILD_IMAGE_NAME" ""
}

@test "builds a missing project image" {
    PMRAILS_TEST_IMAGE_EXISTS_STATUS=1

    pmrails_ensure_image

    assert_equal "$_PMRAILS_IMAGE_NAME" "pmrails-sample_app:3.3.7"
    assert_equal "$PMRAILS_TEST_IMAGE_LOOKUP_NAME" "pmrails-sample_app:3.3.7"
    assert_equal "$PMRAILS_TEST_BUILD_IMAGE_NAME" "pmrails-sample_app:3.3.7"
}

@test "builds a missing project image with a Ruby version suffix" {
    PMRAILS_RUBY_VERSION_SUFFIX="-bookworm"
    PMRAILS_TEST_IMAGE_EXISTS_STATUS=1

    pmrails_ensure_image

    assert_equal "$_PMRAILS_IMAGE_NAME" "pmrails-sample_app:3.3.7-bookworm"
    assert_equal "$PMRAILS_TEST_IMAGE_LOOKUP_NAME" "pmrails-sample_app:3.3.7-bookworm"
    assert_equal "$PMRAILS_TEST_BUILD_IMAGE_NAME" "pmrails-sample_app:3.3.7-bookworm"
}

@test "propagates build failures" {
    PMRAILS_TEST_IMAGE_EXISTS_STATUS=1
    PMRAILS_TEST_BUILD_IMAGE_STATUS=82

    run pmrails_ensure_image

    assert_failure 82
}
