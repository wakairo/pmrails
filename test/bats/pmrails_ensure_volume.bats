#!/usr/bin/env bats
# shellcheck disable=SC2317

load test_helper.bash

install_podman_stub() {
    podman() {
        printf "%s\n" "${PMRAILS_TEST_PODMAN_RUBY_VERSION:-1.2.9}"
        return "${PMRAILS_TEST_PODMAN_RUBY_VERSION_STATUS:-0}"
    }
}

setup() {
    load_pmrails_library
    unset_pmrails_vars
    install_podman_stub
}

@test "creates a Ruby-version-only GEM_HOME volume" {
    _PMRAILS_IMAGE_TAG="1.2.3"
    _PMRAILS_IMAGE_NAME="ruby:${_PMRAILS_IMAGE_TAG}"
    pmrails_ensure_volume
    assert_equal "$_PMRAILS_VOLUME_NAME" "pmrails-gem_home-1.2.3"
}

@test "creates a GEM_HOME volume with an ABI suffix" {
    _PMRAILS_IMAGE_TAG="1.2.3-foo"
    _PMRAILS_IMAGE_NAME="sample_app:${_PMRAILS_IMAGE_TAG}"
    pmrails_ensure_volume
    assert_equal "$_PMRAILS_VOLUME_NAME" "pmrails-gem_home-1.2.3-foo"
}

@test "creates a Ruby-version-only GEM_HOME volume when image tag is latest" {
    _PMRAILS_IMAGE_TAG="latest"
    _PMRAILS_IMAGE_NAME="ruby:${_PMRAILS_IMAGE_TAG}"
    pmrails_ensure_volume
    assert_equal "$_PMRAILS_VOLUME_NAME" "pmrails-gem_home-1.2.9"
}

@test "propagates Ruby version detection failures" {
    _PMRAILS_IMAGE_TAG="latest"
    _PMRAILS_IMAGE_NAME="ruby:${_PMRAILS_IMAGE_TAG}"
    PMRAILS_TEST_PODMAN_RUBY_VERSION_STATUS=76

    run pmrails_ensure_volume

    assert_failure 76
}
