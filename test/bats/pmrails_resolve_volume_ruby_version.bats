#!/usr/bin/env bats

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
}

install_podman_stub() {
    podman() {
        printf "%s\n" "${PMRAILS_TEST_PODMAN_RUBY_VERSION:-1.2.9}"
        return 0
    }
}

@test "extracts a major-minor-patch version from a plain tag without podman" {
    run pmrails_resolve_volume_ruby_version "1.2.3" "ruby:1.2.3"
    assert_success
    assert_output "1.2.3"
}

@test "extracts a major-minor-patch version from a suffixed tag without podman" {
    run pmrails_resolve_volume_ruby_version "1.2.3-slim-foo" "ruby:1.2.3-slim-foo"
    assert_success
    assert_output "1.2.3"
}

@test "extracts only the first three version segments without podman" {
    run pmrails_resolve_volume_ruby_version "1.2.3.4-bookworm" "ruby:1.2.3.4-bookworm"
    assert_success
    assert_output "1.2.3"
}

@test "queries the image when the tag lacks a patch version" {
    install_podman_stub
    run pmrails_resolve_volume_ruby_version "4.0-foo" "ruby:4.0-foo"
    assert_success
    assert_output "1.2.9"
}

@test "queries the image when the tag lacks a minor version" {
    install_podman_stub
    run pmrails_resolve_volume_ruby_version "4-foo" "ruby:4-foo"
    assert_success
    assert_output "1.2.9"
}

@test "queries the image when the tag has no numeric version" {
    install_podman_stub
    run pmrails_resolve_volume_ruby_version "bar" "ruby:bar"
    assert_success
    assert_output "1.2.9"
}

@test "queries the image when a platform tag contains a version-like suffix" {
    install_podman_stub
    run pmrails_resolve_volume_ruby_version "alpine3.23.1" "ruby:alpine3.23.1"
    assert_success
    assert_output "1.2.9"
}
