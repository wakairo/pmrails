# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `pmrails-run` for running arbitrary commands inside a single Rails container with project-local runtime directories under `.pmrails/var/`.
- `pmrails-compose` as the multi-container entrypoint for Compose-based development.
- `pmrails-init` to generate `.pmrails/config`, `.pmrails/Dockerfile`, and `.pmrails/compose.yaml` for an existing Rails project.
- `pmrails-apply-dockerfile` to rebuild the custom Rails image and recreate an existing Compose Rails container after Dockerfile changes.
- A Compose-based development workflow with built-in Selenium support and database presets for SQLite3, PostgreSQL, MySQL, Trilogy, and MariaDB variants.
- Automatic patching of `test/application_system_test_case.rb` during `pmrails-init` so system tests can run against a remote Selenium container.
- Layered configuration loading from system, user, project, and project-local config files.
- Support for `PMRAILS_RUBY_VERSION`, `PMRAILS_RUBY_VERSION_SUFFIX`, `PMRAILS_RUBY_VERSION_AT_NEW`, `PMRAILS_PORTS`, `PMRAILS_PROJECT_NAME`, `PMRAILS_DOCKERFILE`, `PMRAILS_BUILD_CONTEXT`, and `PMRAILS_COMPOSE_FILE`.
- Support for custom `Dockerfile` and `compose.yaml`, with a dedicated build context for project-specific images.
- Introduce shared `GEM_HOME` named volumes so compatible PmRails containers can reuse installed gems, with stores separated by resolved Ruby version and ABI suffix to avoid mixing native extensions across incompatible runtimes.
- An `aliases` file with shorthand commands for common `pmrails-run` and `pmrails-compose` invocations.
- Project development tooling and quality gates, including `Rakefile` tasks, RuboCop, SimpleCov, Bats, ShellCheck, shfmt, kcov, `.editorconfig`, `.gitignore`, and `.rubocop.yml`.
- Automated shell and Ruby test coverage for the new CLI and configuration-generation paths.

### Changed

- `pmrails-new` and `pmrails-new-plus` now use the shared `lib/pmrails.sh` runtime setup instead of carrying their own inline Podman logic.
- `pmrails-new-plus` now adds both `/.pmrails/var/` and `/.pmrails/config.local` to the generated app's `.gitignore`.
- Plain numeric Rails versions passed to `pmrails-new` and `pmrails-new-plus` are expanded to pessimistic RubyGems requirements, so `8.1` installs the latest compatible `8.1.x` release.
- Legacy entrypoints now delegate to the new command surface instead of duplicating container-launch logic.
- CLI usage errors now consistently begin with `Usage:`.

### Deprecated

- `pmrails`; use `pmrails-run bin/rails` instead.
- `pmbundle`; use `pmrails-run bundle` instead.
- `pmrailsenvexec` (renamed to `pmrails-run`); use `pmrails-run` instead.


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
