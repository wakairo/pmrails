#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2034

load test_helper.bash

reset_recorded_calls() {
    local i

    for ((i = 1; i <= ${PMRAILS_TEST_CALL_COUNT:-0}; i++)); do
        unset "PMRAILS_TEST_CALL_${i}"
    done

    PMRAILS_TEST_CALL_COUNT=0
}

record_call() {
    local var_name

    PMRAILS_TEST_CALL_COUNT=$((PMRAILS_TEST_CALL_COUNT + 1))
    var_name="PMRAILS_TEST_CALL_${PMRAILS_TEST_CALL_COUNT}"

    declare -g -a "$var_name"
    local -n ref="$var_name"
    ref=("$@")
}

assert_array_equals() {
    local actual_name="$1"
    local expected_name="$2"
    local i
    local -n actual="$actual_name"
    local -n expected="$expected_name"

    assert_equal "${#actual[@]}" "${#expected[@]}"
    for i in "${!expected[@]}"; do
        assert_equal "${actual[$i]}" "${expected[$i]}"
    done
}

assert_recorded_call_equals() {
    local index="$1"
    local expected_name="$2"
    local actual_name="PMRAILS_TEST_CALL_${index}"

    if ! declare -p "$actual_name" >/dev/null 2>&1; then
        fail "recorded call $index does not exist"
    fi

    assert_array_equals "$actual_name" "$expected_name"
}

install_podman_stub() {
    podman() {
        record_call "$@"

        if [ "$1" = "image" ] && [ "$2" = "exists" ]; then
            return "${PMRAILS_TEST_PODMAN_IMAGE_EXISTS_STATUS:-0}"
        fi

        return 0
    }
}

install_exec_stub() {
    exec() {
        PMRAILS_TEST_GENERATE_COUNT_AT_EXEC="${PMRAILS_TEST_GENERATE_OVERRIDE_CALLS:-0}"
        PMRAILS_TEST_BUILD_PORTS_COUNT_AT_EXEC="${PMRAILS_TEST_BUILD_PORTS_CALLS:-0}"
        record_call "$@"
        return 0
    }
}

install_generate_compose_override_stub() {
    pmrails_generate_compose_override() {
        PMRAILS_TEST_GENERATE_OVERRIDE_CALLS=$((PMRAILS_TEST_GENERATE_OVERRIDE_CALLS + 1))
    }
}

install_build_ports_args_stub() {
    pmrails_build_ports_args() {
        PMRAILS_TEST_BUILD_PORTS_CALLS=$((PMRAILS_TEST_BUILD_PORTS_CALLS + 1))
        _PMRAILS_PORTS_ARGS="${PMRAILS_TEST_STUB_PORTS_ARGS:-}"
    }
}

install_stdout_is_tty_stub() {
    pmrails_stdout_is_tty() {
        return 0
    }
}

setup() {
    load_pmrails_library
    unset_pmrails_vars
    cd "$BATS_TEST_TMPDIR" || exit 1

    reset_recorded_calls
    PMRAILS_TEST_PODMAN_IMAGE_EXISTS_STATUS=0
    PMRAILS_TEST_GENERATE_OVERRIDE_CALLS=0
    PMRAILS_TEST_GENERATE_COUNT_AT_EXEC=""
    PMRAILS_TEST_BUILD_PORTS_CALLS=0
    PMRAILS_TEST_BUILD_PORTS_COUNT_AT_EXEC=""
    PMRAILS_TEST_STUB_PORTS_ARGS=""

    PMRAILS_IMAGE_REPO="pmrails-sample_app"
    PMRAILS_RUBY_VERSION="3.3.7"
    PMRAILS_DOCKERFILE=".pmrails/Dockerfile"
    PMRAILS_PROJECT_NAME="sample_app"
    PMRAILS_COMPOSE_FILE=".pmrails/compose.yaml"
    PMRAILS_RUBY_VERSION_AT_NEW="3.4.1"
    _PMRAILS_IMAGE_NAME="pmrails-sample_app:3.3.7"
    _PMRAILS_SCRIPT_DIR="/opt/pmrails/bin"
}

@test "pmrails_ensure_image sets the image name and skips podman for the upstream ruby image" {
    install_podman_stub
    PMRAILS_IMAGE_REPO="ruby"
    PMRAILS_RUBY_VERSION="3.2.2"

    pmrails_ensure_image

    assert_equal "$_PMRAILS_IMAGE_NAME" "ruby:3.2.2"
    assert_equal "$PMRAILS_TEST_CALL_COUNT" "0"
}

@test "pmrails_ensure_image skips building when the project image already exists" {
    local expected_call=(
        image
        exists
        pmrails-sample_app:3.3.7
    )

    install_podman_stub
    PMRAILS_TEST_PODMAN_IMAGE_EXISTS_STATUS=0

    pmrails_ensure_image

    assert_equal "$_PMRAILS_IMAGE_NAME" "pmrails-sample_app:3.3.7"
    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_ensure_image builds the image when it is missing" {
    local expected_exists_call=(
        image
        exists
        pmrails-sample_app:3.3.7
    )
    local expected_build_call=(
        build
        --build-arg
        PMRAILS_RUBY_VERSION=3.3.7
        -t
        pmrails-sample_app:3.3.7
        -f
        .pmrails/Dockerfile
        .
    )

    install_podman_stub
    PMRAILS_TEST_PODMAN_IMAGE_EXISTS_STATUS=1

    pmrails_ensure_image

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "2"
    assert_recorded_call_equals 1 expected_exists_call
    assert_recorded_call_equals 2 expected_build_call
}

@test "pmrails_exec_podman_compose generates the override before exec and forwards each compose argument individually" {
    local expected_call=(
        env
        PMRAILS_RUBY_VERSION=3.3.7
        _PMRAILS_VAR_DIR=.pmrails/var
        _PMRAILS_IMAGE_NAME=pmrails-sample_app:3.3.7
        podman-compose
        -p
        sample_app
        -f
        /opt/pmrails/bin/../share/compose.base.yaml
        -f
        .pmrails/var/compose.override.yaml
        -f
        .pmrails/compose.yaml
        up
        rails-app
        --detach
    )

    install_generate_compose_override_stub
    install_exec_stub

    pmrails_exec_podman_compose up rails-app --detach

    assert_equal "$PMRAILS_TEST_GENERATE_OVERRIDE_CALLS" "1"
    assert_equal "$PMRAILS_TEST_GENERATE_COUNT_AT_EXEC" "1"
    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_exec_podman_run builds port arguments before exec and passes each podman argument individually (no TTY)" {
    local expected_call=(
        podman
        run
        -i
        --rm
        --userns=keep-id
        -p
        3000:3000
        -p
        1234:1234
        -v
        "$PWD:/x"
        -w
        /x
        --env
        HOME=/x/.pmrails/var/home
        --env
        XDG_CACHE_HOME=/x/.pmrails/var/cache
        --env
        XDG_CONFIG_HOME=/x/.pmrails/var/config
        --env
        XDG_DATA_HOME=/x/.pmrails/var/share
        --env
        XDG_STATE_HOME=/x/.pmrails/var/state
        --env
        BUNDLE_PATH=/x/.pmrails/var/bundle
        pmrails-sample_app:3.3.7
        bundle
        exec
        rake
        test
    )

    install_build_ports_args_stub
    install_exec_stub
    PMRAILS_TEST_STUB_PORTS_ARGS="-p 3000:3000 -p 1234:1234"

    pmrails_exec_podman_run bundle exec rake test >/dev/null

    assert_equal "$PMRAILS_TEST_BUILD_PORTS_CALLS" "1"
    assert_equal "$PMRAILS_TEST_BUILD_PORTS_COUNT_AT_EXEC" "1"
    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_exec_podman_run appends -t when STDOUT is a TTY" {
    local expected_call=(
        podman
        run
        -i
        -t
        --rm
        --userns=keep-id
        -p
        3000:3000
        -v
        "$PWD:/x"
        -w
        /x
        --env
        HOME=/x/.pmrails/var/home
        --env
        XDG_CACHE_HOME=/x/.pmrails/var/cache
        --env
        XDG_CONFIG_HOME=/x/.pmrails/var/config
        --env
        XDG_DATA_HOME=/x/.pmrails/var/share
        --env
        XDG_STATE_HOME=/x/.pmrails/var/state
        --env
        BUNDLE_PATH=/x/.pmrails/var/bundle
        pmrails-sample_app:3.3.7
        bin/rails
        -v
    )

    install_build_ports_args_stub
    install_exec_stub
    install_stdout_is_tty_stub
    PMRAILS_TEST_STUB_PORTS_ARGS="-p 3000:3000"

    pmrails_exec_podman_run bin/rails -v

    assert_equal "$PMRAILS_TEST_BUILD_PORTS_CALLS" "1"
    assert_equal "$PMRAILS_TEST_BUILD_PORTS_COUNT_AT_EXEC" "1"
    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_exec_podman_run omits all port flags when the port builder returns an empty string (no TTY)" {
    local expected_call=(
        podman
        run
        -i
        --rm
        --userns=keep-id
        -v
        "$PWD:/x"
        -w
        /x
        --env
        HOME=/x/.pmrails/var/home
        --env
        XDG_CACHE_HOME=/x/.pmrails/var/cache
        --env
        XDG_CONFIG_HOME=/x/.pmrails/var/config
        --env
        XDG_DATA_HOME=/x/.pmrails/var/share
        --env
        XDG_STATE_HOME=/x/.pmrails/var/state
        --env
        BUNDLE_PATH=/x/.pmrails/var/bundle
        pmrails-sample_app:3.3.7
        ruby
        -v
    )

    install_build_ports_args_stub
    install_exec_stub
    PMRAILS_TEST_STUB_PORTS_ARGS=""

    pmrails_exec_podman_run ruby -v >/dev/null

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_podman_run_rails_new forwards _PMRAILS_ADDITIONAL_ARGS and rails-new arguments individually (no TTY)" {
    local expected_call=(
        run
        -i
        --rm
        --userns=keep-id
        -v
        "$PWD:/x"
        -w
        /x
        --tmpfs
        /home/pmrails
        --env
        HOME=/home/pmrails
        --network
        host
        --cap-add
        SYS_PTRACE
        ruby:3.4.1
        sh
        -c
        'ver="$1"; shift; gem install rails --no-document -v "${ver}" && rails new "$@"'
        --
        8.0.2
        blog
        --skip-bundle
        --css
        tailwind
    )

    install_podman_stub
    _PMRAILS_ADDITIONAL_ARGS="--network host --cap-add SYS_PTRACE"

    pmrails_podman_run_rails_new 8.0.2 blog --skip-bundle --css tailwind >/dev/null

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_podman_run_rails_new omits additional podman arguments when _PMRAILS_ADDITIONAL_ARGS is unset (no TTY)" {
    local expected_call=(
        run
        -i
        --rm
        --userns=keep-id
        -v
        "$PWD:/x"
        -w
        /x
        --tmpfs
        /home/pmrails
        --env
        HOME=/home/pmrails
        ruby:3.4.1
        sh
        -c
        'ver="$1"; shift; gem install rails --no-document -v "${ver}" && rails new "$@"'
        --
        7.2.0
        myapp
    )

    install_podman_stub
    unset _PMRAILS_ADDITIONAL_ARGS

    pmrails_podman_run_rails_new 7.2.0 myapp >/dev/null

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_podman_run_rails_new appends -t when STDOUT is a TTY" {
    local expected_call=(
        run
        -i
        -t
        --rm
        --userns=keep-id
        -v
        "$PWD:/x"
        -w
        /x
        --tmpfs
        /home/pmrails
        --env
        HOME=/home/pmrails
        ruby:3.4.1
        sh
        -c
        'ver="$1"; shift; gem install rails --no-document -v "${ver}" && rails new "$@"'
        --
        8.1.1
        store
    )

    install_podman_stub
    install_stdout_is_tty_stub
    unset _PMRAILS_ADDITIONAL_ARGS

    pmrails_podman_run_rails_new 8.1.1 store

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}
