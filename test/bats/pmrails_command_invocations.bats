#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2034,SC2054

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

bash_array_inspect() {
    local array_name="$1"
    local i
    local inspected="("
    local quoted
    local -n array="$array_name"

    for i in "${!array[@]}"; do
        printf -v quoted "%q" "${array[$i]}"
        inspected+="[$i]=$quoted "
    done

    inspected="${inspected% }"
    inspected+=")"
    printf "%s\n" "$inspected"
}

assert_array_equals() {
    local actual_name="$1"
    local expected_name="$2"
    local actual_inspect
    local expected_inspect

    actual_inspect="$(bash_array_inspect "$actual_name")"
    expected_inspect="$(bash_array_inspect "$expected_name")"

    if [ "$actual_inspect" != "$expected_inspect" ]; then
        batslib_print_kv_single_or_multi 8 \
            "expected" "$expected_inspect" \
            "actual" "$actual_inspect" |
            batslib_decorate "arrays differ" |
            fail
    fi
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
        PMRAILS_TEST_BUILD_PORTS_COUNT_AT_EXEC="${PMRAILS_TEST_BUILD_PORTS_CALLS:-0}"
        record_call "$@"
        return 0
    }
}

install_env_stub() {
    env() {
        PMRAILS_TEST_GENERATE_COUNT_AT_ENV="${PMRAILS_TEST_GENERATE_OVERRIDE_CALLS:-0}"
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
    PMRAILS_RUBY_VERSION_SUFFIX=""
    PMRAILS_DOCKERFILE=".pmrails/Dockerfile"
    PMRAILS_PROJECT_NAME="sample_app"
    PMRAILS_COMPOSE_FILE=".pmrails/compose.yaml"
    PMRAILS_RUBY_VERSION_AT_NEW="3.4.1"
    _PMRAILS_IMAGE_NAME="pmrails-sample_app:3.3.7"
    _PMRAILS_VOLUME_NAME="pmrails-gem_home-4.0.3"
    _PMRAILS_SCRIPT_DIR="/opt/pmrails/bin"
    PMRAILS_TEST_RAILS_NEW_SCRIPT=$'\nset -eu\nver="$1"\nshift\ngem_out=$(gem install rails -v "${ver}") || exit $?\nreal_ver=$(printf "%s\\n" "${gem_out}" | sed -nE "/\\.gem([[:space:]]|\\$)/d; s/(^|.*[[:space:]])rails-([0-9][0-9A-Za-z.]*)([[:space:]]|\\$).*/\\2/p" | tail -n 1)\nif [ -z "${real_ver}" ]; then\n    printf "pmrails: error: could not extract the installed Rails version from \\"gem install rails -v %s\\" output\\n" "${ver}" >&2\n    exit 1\nfi\nprintf "pmrails: using Rails version %s for rails new\\n" "${real_ver}"\nexec rails "_${real_ver}_" new "$@"\n'
}

@test "assert_array_equals reports full expected and actual arrays on mismatch" {
    local expected=(
        alpha
        "two words"
        gamma
    )
    local actual=(
        alpha
        different
        gamma
        extra
    )

    run assert_array_equals actual expected

    assert_failure
    assert_output --partial "-- arrays differ --"
    assert_output --partial "expected : ([0]=alpha [1]=two\\ words [2]=gamma)"
    assert_output --partial "actual   : ([0]=alpha [1]=different [2]=gamma [3]=extra)"
}

@test "pmrails_ensure_image selects the upstream ruby image without podman checks" {
    install_podman_stub
    PMRAILS_IMAGE_REPO="ruby"
    PMRAILS_RUBY_VERSION="3.2.2"

    pmrails_ensure_image

    assert_equal "$_PMRAILS_IMAGE_NAME" "ruby:3.2.2"
    assert_equal "$PMRAILS_TEST_CALL_COUNT" "0"
}

@test "pmrails_ensure_image reuses an existing project image" {
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

@test "pmrails_ensure_image builds a missing project image" {
    local expected_exists_call=(
        image
        exists
        pmrails-sample_app:3.3.7
    )
    local expected_build_call=(
        build
        --build-arg
        PMRAILS_RUBY_VERSION=3.3.7
        --build-arg
        PMRAILS_RUBY_VERSION_SUFFIX=
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

@test "pmrails_ensure_image builds a missing project image with suffix" {
    local expected_exists_call=(
        image
        exists
        pmrails-sample_app:3.3.7-bookworm
    )
    local expected_build_call=(
        build
        --build-arg
        PMRAILS_RUBY_VERSION=3.3.7
        --build-arg
        PMRAILS_RUBY_VERSION_SUFFIX=-bookworm
        -t
        pmrails-sample_app:3.3.7-bookworm
        -f
        .pmrails/Dockerfile
        .
    )

    install_podman_stub
    PMRAILS_TEST_PODMAN_IMAGE_EXISTS_STATUS=1

    PMRAILS_RUBY_VERSION_SUFFIX="-bookworm"
    pmrails_ensure_image

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "2"
    assert_recorded_call_equals 1 expected_exists_call
    assert_recorded_call_equals 2 expected_build_call
}

@test "pmrails_podman_compose generates the port override before running and preserves compose arguments" {
    local expected_call=(
        PMRAILS_RUBY_VERSION=3.3.7
        _PMRAILS_SCRIPT_DIR=/opt/pmrails/bin
        _PMRAILS_GEM_HOME=/gem-home
        _PMRAILS_VOLUME_NAME=pmrails-gem_home-4.0.3
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
    install_env_stub

    pmrails_podman_compose up rails-app --detach

    assert_equal "$PMRAILS_TEST_GENERATE_OVERRIDE_CALLS" "1"
    assert_equal "$PMRAILS_TEST_GENERATE_COUNT_AT_ENV" "1"
    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_exec_podman_run builds port flags before exec and preserves command arguments without TTY" {
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
        pmrails-gem_home-4.0.3:/gem-home
        --env
        GEM_HOME=/gem-home
        -v
        /opt/pmrails/bin/../share/entrypoint:/pmrails-entrypoint:ro,z
        --entrypoint
        /pmrails-entrypoint
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

@test "pmrails_exec_podman_run adds a TTY flag when STDOUT is a TTY" {
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
        pmrails-gem_home-4.0.3:/gem-home
        --env
        GEM_HOME=/gem-home
        -v
        /opt/pmrails/bin/../share/entrypoint:/pmrails-entrypoint:ro,z
        --entrypoint
        /pmrails-entrypoint
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

@test "pmrails_exec_podman_run omits port flags when no ports are built" {
    local expected_call=(
        podman
        run
        -i
        --rm
        --userns=keep-id
        -v
        pmrails-gem_home-4.0.3:/gem-home
        --env
        GEM_HOME=/gem-home
        -v
        /opt/pmrails/bin/../share/entrypoint:/pmrails-entrypoint:ro,z
        --entrypoint
        /pmrails-entrypoint
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

@test "pmrails_podman_run_rails_new expands the Rails requirement and preserves rails new arguments without TTY" {
    local expected_call=(
        run
        -i
        --rm
        --userns=keep-id
        -v
        pmrails-gem_home-4.0.3:/gem-home
        --env
        GEM_HOME=/gem-home
        -v
        /opt/pmrails/bin/../share/entrypoint:/pmrails-entrypoint:ro,z
        --entrypoint
        /pmrails-entrypoint
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
        "$PMRAILS_TEST_RAILS_NEW_SCRIPT"
        --
        "~> 8.0.2.0"
        blog
        --skip-bundle
        --css
        tailwind
    )

    install_podman_stub

    _PMRAILS_IMAGE_NAME="ruby:3.4.1"
    pmrails_podman_run_rails_new 8.0.2 blog --skip-bundle --css tailwind >/dev/null

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_podman_run_rails_new reports the expanded Rails requirement" {
    install_podman_stub

    _PMRAILS_IMAGE_NAME="ruby:3.4.1"
    run pmrails_podman_run_rails_new 8.1 blog

    assert_success
    assert_output --partial 'pmrails: using Rails version requirement "~> 8.1.0" for "8.1"'
}

@test "pmrails_podman_run_rails_new adds a TTY flag and preserves explicit Rails requirements" {
    local expected_call=(
        run
        -i
        -t
        --rm
        --userns=keep-id
        -v
        pmrails-gem_home-4.0.3:/gem-home
        --env
        GEM_HOME=/gem-home
        -v
        /opt/pmrails/bin/../share/entrypoint:/pmrails-entrypoint:ro,z
        --entrypoint
        /pmrails-entrypoint
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
        "$PMRAILS_TEST_RAILS_NEW_SCRIPT"
        --
        "= 8.1"
        store
    )

    install_podman_stub
    install_stdout_is_tty_stub

    _PMRAILS_IMAGE_NAME="ruby:3.4.1"
    pmrails_podman_run_rails_new '= 8.1' store

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_exec_podman_run_init preserves init arguments without TTY" {
    local expected_call=(
        podman
        run
        -i
        --rm
        --userns=keep-id
        -v
        pmrails-gem_home-4.0.3:/gem-home
        --env
        GEM_HOME=/gem-home
        -v
        /opt/pmrails/bin/../share/entrypoint:/pmrails-entrypoint:ro,z
        --entrypoint
        /pmrails-entrypoint
        -v
        /opt/pmrails/bin/../lib:/pmrails/lib:ro,z
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
        'gem install --conservative thor activesupport && ruby /pmrails/lib/pmrails.rb init "$@"'
        --
        -d
        mysql
    )

    install_exec_stub

    _PMRAILS_IMAGE_NAME="ruby:3.4.1"
    pmrails_exec_podman_run_init -d mysql

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}

@test "pmrails_exec_podman_run_init adds a TTY flag when STDOUT is a TTY" {
    local expected_call=(
        podman
        run
        -i
        -t
        --rm
        --userns=keep-id
        -v
        pmrails-gem_home-4.0.3:/gem-home
        --env
        GEM_HOME=/gem-home
        -v
        /opt/pmrails/bin/../share/entrypoint:/pmrails-entrypoint:ro,z
        --entrypoint
        /pmrails-entrypoint
        -v
        /opt/pmrails/bin/../lib:/pmrails/lib:ro,z
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
        'gem install --conservative thor activesupport && ruby /pmrails/lib/pmrails.rb init "$@"'
        --
        -d
        mysql
    )

    install_exec_stub
    install_stdout_is_tty_stub

    _PMRAILS_IMAGE_NAME="ruby:3.4.1"
    pmrails_exec_podman_run_init -d mysql

    assert_equal "$PMRAILS_TEST_CALL_COUNT" "1"
    assert_recorded_call_equals 1 expected_call
}
