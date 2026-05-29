#!/usr/bin/env bats

load test_helper.bash

setup() {
    load_pmrails_library
    unset_pmrails_vars
}

auto_unset_config_vars=(
    PMRAILS_RUBY_VERSION
    PMRAILS_RUBY_VERSION_SUFFIX
    PMRAILS_RUBY_VERSION_AT_NEW
    PMRAILS_PORTS
    PMRAILS_PROJECT_NAME
    PMRAILS_DOCKERFILE
    PMRAILS_COMPOSE_FILE
    PMRAILS_GEM_HOME_ABI
    PMRAILS_IMAGE_REPO
)

@test "unsets every runtime configuration variable set to :AUTO" {
    local var

    for var in "${auto_unset_config_vars[@]}"; do
        printf -v "$var" "%s" ":AUTO"
    done

    pmrails_unset_auto_config_variables

    for var in "${auto_unset_config_vars[@]}"; do
        if [[ -v $var ]]; then
            fail "$var should be unset"
        fi
    done
}

@test "preserves normal literal values for every runtime configuration variable" {
    local var
    local value

    for var in "${auto_unset_config_vars[@]}"; do
        value="literal-${var}"
        printf -v "$var" "%s" "$value"
    done

    pmrails_unset_auto_config_variables

    for var in "${auto_unset_config_vars[@]}"; do
        value="literal-${var}"
        assert_equal "${!var}" "$value"
    done
}

@test "does not unset PMRAILS_SYS_CONF because it controls config loading" {
    PMRAILS_SYS_CONF=":AUTO"

    pmrails_unset_auto_config_variables

    assert_equal "$PMRAILS_SYS_CONF" ":AUTO"
}

@test "preserves explicit empty strings while unsetting auto config variables" {
    PMRAILS_PORTS=""

    pmrails_unset_auto_config_variables

    assert_equal "${PMRAILS_PORTS+set}" "set"
    assert_equal "$PMRAILS_PORTS" ""
}
