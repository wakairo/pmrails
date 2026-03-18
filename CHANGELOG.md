# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


## [1.1.0] - 2026-03-18

### Added

- Introduce the `.pmrails/var` directory to store project-local runtime data (gems, caches, configuration, etc.) in isolation.
- Map container environment variables (`HOME`, `XDG_CACHE_HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`) to the `.pmrails/var` directory to keep the host environment clean.
- Implement a new command, `pmrails-new-plus`, which automates the entire setup process: creating a Rails app, installing gems, and updating `.gitignore`.
- Add Podman's `--userns=keep-id` option to all basic commands to support Fedora Immutable systems with SELinux.
- Update the README (English and Japanese) with sections on Ruby version resolution, external database connections (via `host.containers.internal`), and SELinux considerations.

### Changed

- Relocate the default gem installation path from `vendor/bundle/` to `.pmrails/var/bundle/`.
- Improve `.ruby-version` parsing to strictly extract a `MAJOR.MINOR.PATCH` pattern from the first line only, with clearer error messages on failure.
- Enhance script reliability by enforcing strict error handling using `set -eu` across all shell scripts.
- Refine `pmrails-new` to focus solely on application generation, while `pmrails-new-plus` handles both app creation and development setup.
- Use `tmpfs` for the `/home/pmrails` directory in `pmrails-new` and `pmrails-new-plus` to ensure a clean execution environment.

### Fixed

- Fix argument handling in all shell scripts to correctly support arguments containing spaces by using `"$@"` instead of `$*`.
- Fix an issue where post-generation tasks (e.g., importmap/turbo installation) were skipped by removing the `--skip-bundle` flag.


## [1.0.0] - 2024-12-31

- Initial release

### Added

- Implement four basic commands.
