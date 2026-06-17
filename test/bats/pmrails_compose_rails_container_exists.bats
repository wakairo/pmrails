#!/usr/bin/env bats
# shellcheck disable=SC2034,SC2317

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars

    PMRAILS_PROJECT_NAME="sample_app"

    podman() {
        printf '%s' "${PMRAILS_TEST_PODMAN_PS_OUTPUT:-}"
        return "${PMRAILS_TEST_PODMAN_PS_STATUS:-0}"
    }
}

@test "returns success when podman outputs a container id" {
    PMRAILS_TEST_PODMAN_PS_OUTPUT="rails-container-id"

    pmrails_compose_rails_container_exists
}

@test "returns failure when no rails-app container exists" {
    run pmrails_compose_rails_container_exists

    assert_failure 1
}

@test "propagates podman ps failures" {
    PMRAILS_TEST_PODMAN_PS_STATUS=125

    run pmrails_compose_rails_container_exists

    assert_failure 125
}
