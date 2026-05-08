set -u
bats_load_library bats-support
bats_load_library bats-assert

project_root() {
    cd "$BATS_TEST_DIRNAME/../.." && pwd
}

load_pmrails_library() {
    source "$(project_root)/lib/pmrails.sh"
}

# Unsets all caller-facing PMRAILS_* variables (does not touch _PMRAILS_* internals).
unset_pmrails_vars() {
    local name

    while IFS= read -r name; do
        case "$name" in
        PMRAILS_*)
            unset "$name"
            ;;
        esac
    done < <(compgen -A variable)
}

write_lines_to() {
    local path="$1"
    shift

    mkdir -p "$(dirname "$path")"
    printf '%s\n' "$@" >"$path"
}

enter_test_project_dir() {
    local path="$BATS_TEST_TMPDIR/$1"

    mkdir -p "$path"
    cd "$path" || exit 1
}
