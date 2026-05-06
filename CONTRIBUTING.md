Bug reports and pull requests are welcome on GitHub!
PmRails uses a single `Rakefile` to orchestrate tests, linters, and formatters for both the Ruby codebase and the shell scripts.

### Prerequisites for Development

To run the shell script test suite, install the following tools.
On Ubuntu/Debian, you can install them via `apt`:

```sh
sudo apt install bats bats-support bats-assert shellcheck shfmt
```

[`kcov`](https://github.com/SimonKagstrom/kcov) is also recommended if you want to generate shell script test coverage locally.

For Ruby test coverage, install SimpleCov:

```sh
sudo gem install simplecov
```

### Running Tests and Linters

All tests and linters must pass before a pull request can be merged. The Rakefile provides convenient tasks to handle this:

- **`rake ci`**: Runs the complete CI pipeline (Lint -> Format Check -> Test) for both Ruby and Shell. **Run this before pushing your commits.**
- **`rake test`**: Runs only the test suites (`minitest` and `bats`), skipping the linters.
- **`rake shell:format:fix`**: Automatically applies standard formatting to all shell scripts using `shfmt`.
- **`rake ruby:rubocop:autocorrect`**: Autocorrects RuboCop offenses (only when safe to do so).
- **`rake ruby:coverage` / `rake shell:coverage`**: Runs tests and generates HTML coverage reports in the `coverage/` directory.
  > *Note on Coverage: You do not need to aim for 100% coverage. We use it primarily as a diagnostic tool to ensure tests are exercising the intended paths. For shell scripts in particular, due to technical limitations in `kcov` and `bash`, lines inside or around subshells (e.g., `(...)` or `$(...)`) are sometimes incorrectly reported as uncovered.*

See `rake --tasks` for more details.

### Updating Golden Master Fixtures

Tests for the `pmrails-init` command rely on the **Golden Master (Snapshot) pattern**. They compare the actual generated files (`compose.yaml`, `Dockerfile`, etc.) against a set of expected fixtures.

If you modify the generation logic or templates, these tests will intentionally fail. To update the expected fixtures to match your new logic, run:

```sh
rake ruby:test:update_golden_master
```

> **Tip:** Always use `git diff` after running this task to carefully verify the changes in `test/ruby/fixtures/expected/` before committing them. This ensures your modifications produced the exact output you intended.
