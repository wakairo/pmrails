#!/usr/bin/env bats
# shellcheck disable=SC2317

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
    cd "$BATS_TEST_TMPDIR" || exit 1

    PMRAILS_DOCKERFILE=".pmrails/Dockerfile"
    PMRAILS_COMPOSE_FILE=".pmrails/compose.yaml"

    PMRAILS_TEST_RESOLVE_IMAGE_CALLS=0
    PMRAILS_TEST_BUILD_IMAGE_CALLS=0
    PMRAILS_TEST_CONTAINER_EXISTS_STATUS=1
    PMRAILS_TEST_COMPOSE_CALLS=0
    PMRAILS_TEST_OUTPUT_FILE="${BATS_TEST_TMPDIR}/output"

    pmrails_resolve_image() {
        PMRAILS_TEST_RESOLVE_IMAGE_CALLS=$((PMRAILS_TEST_RESOLVE_IMAGE_CALLS + 1))
    }
    pmrails_build_image() {
        PMRAILS_TEST_BUILD_IMAGE_CALLS=$((PMRAILS_TEST_BUILD_IMAGE_CALLS + 1))
    }
    pmrails_compose_rails_container_exists() {
        return "${PMRAILS_TEST_CONTAINER_EXISTS_STATUS}"
    }
    pmrails_ensure_volume() {
        return 0
    }
    pmrails_ensure_home_dir() {
        return 0
    }
    pmrails_podman_compose() {
        PMRAILS_TEST_COMPOSE_CALLS=$((PMRAILS_TEST_COMPOSE_CALLS + 1))
    }
}

@test "does nothing when the configured Dockerfile does not exist" {
    pmrails_apply_dockerfile >"$PMRAILS_TEST_OUTPUT_FILE"

    grep -Fq 'Dockerfile not found' "$PMRAILS_TEST_OUTPUT_FILE"
    grep -Fq 'nothing to apply' "$PMRAILS_TEST_OUTPUT_FILE"
    assert_equal "$PMRAILS_TEST_RESOLVE_IMAGE_CALLS" "0"
    assert_equal "$PMRAILS_TEST_BUILD_IMAGE_CALLS" "0"
}

@test "builds only when no Compose file exists" {
    write_lines_to "$PMRAILS_DOCKERFILE" "FROM ruby:latest"

    pmrails_apply_dockerfile >"$PMRAILS_TEST_OUTPUT_FILE"

    grep -Fq 'building the Rails image' "$PMRAILS_TEST_OUTPUT_FILE"
    assert_equal "$PMRAILS_TEST_RESOLVE_IMAGE_CALLS" "1"
    assert_equal "$PMRAILS_TEST_BUILD_IMAGE_CALLS" "1"
    assert_equal "$PMRAILS_TEST_COMPOSE_CALLS" "0"
}

@test "builds only when no Compose Rails container exists" {
    write_lines_to "$PMRAILS_DOCKERFILE" "FROM ruby:latest"
    write_lines_to "$PMRAILS_COMPOSE_FILE" "services: {}"

    pmrails_apply_dockerfile >"$PMRAILS_TEST_OUTPUT_FILE"

    grep -Fq 'only the image was rebuilt' "$PMRAILS_TEST_OUTPUT_FILE"
    assert_equal "$PMRAILS_TEST_RESOLVE_IMAGE_CALLS" "1"
    assert_equal "$PMRAILS_TEST_BUILD_IMAGE_CALLS" "1"
    assert_equal "$PMRAILS_TEST_COMPOSE_CALLS" "0"
}

@test "recreates the existing Compose Rails container and brings the environment up" {
    write_lines_to "$PMRAILS_DOCKERFILE" "FROM ruby:latest"
    write_lines_to "$PMRAILS_COMPOSE_FILE" "services: {}"
    PMRAILS_TEST_CONTAINER_EXISTS_STATUS=0

    pmrails_apply_dockerfile >"$PMRAILS_TEST_OUTPUT_FILE"

    assert_equal "$PMRAILS_TEST_RESOLVE_IMAGE_CALLS" "1"
    assert_equal "$PMRAILS_TEST_BUILD_IMAGE_CALLS" "1"
    assert_equal "$PMRAILS_TEST_COMPOSE_CALLS" "2"
}
