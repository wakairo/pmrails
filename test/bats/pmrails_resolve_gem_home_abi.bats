#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
    _PMRAILS_IMAGE_TAG="4.0.3-trixie"
}

@test "preserves an explicit GEM_HOME ABI suffix" {
    PMRAILS_GEM_HOME_ABI="kitten"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" "kitten"
}

@test "preserves an explicit empty GEM_HOME ABI suffix" {
    PMRAILS_GEM_HOME_ABI=""
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" ""
}

@test "resolves latest to an empty ABI suffix" {
    unset PMRAILS_GEM_HOME_ABI
    _PMRAILS_IMAGE_TAG="latest"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" ""
}

@test "derives ABI suffix after a major-minor-patch version and hyphen" {
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" "trixie"
}

@test "derives ABI suffix after a major-minor version and hyphen" {
    _PMRAILS_IMAGE_TAG="4.0-trixie"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" "trixie"
}

@test "derives ABI suffix after a major version and hyphen" {
    _PMRAILS_IMAGE_TAG="4-trixie"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" "trixie"
}

@test "derives ABI suffix after a version and underscore" {
    _PMRAILS_IMAGE_TAG="4.0.3_slim-trixie"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" "_slim-trixie"
}

@test "derives ABI suffix after a version without a separator" {
    _PMRAILS_IMAGE_TAG="4.0.7foo"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" "foo"
}

@test "resolves a version-only image tag to an empty ABI suffix" {
    _PMRAILS_IMAGE_TAG="4.0.3"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" ""
}

@test "uses an image tag without a leading version as the ABI suffix" {
    _PMRAILS_IMAGE_TAG="bookworm"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" "bookworm"
}

@test "derives ABI suffix after a long version prefix" {
    _PMRAILS_IMAGE_TAG="1.2.3.4.5-alpine3.23"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" ".4.5-alpine3.23"
}

@test "preserves version-like text in the derived ABI suffix" {
    _PMRAILS_IMAGE_TAG="1.2.3-4.5.6-alpine3.23"
    pmrails_resolve_gem_home_abi
    assert_equal "$PMRAILS_GEM_HOME_ABI" "4.5.6-alpine3.23"
}
