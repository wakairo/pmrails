# frozen_string_literal: true

require "fileutils"
require "open3"
require "rake/testtask"
require "rubocop/rake_task"

RAKE_DIR = ".rake"
PRE_COMMIT_HOOK_SOURCE = ".githooks/pre-commit"
RUBY_RUBOCOP_STAMP = "#{RAKE_DIR}/ruby_rubocop.stamp"
RUBY_RUBOCOP_TARGETS = %w[.simplecov Rakefile lib/*.rb test/ruby/*.rb]

directory RAKE_DIR

# Returns target files that require processing since the stamp was last updated.
# A forced build, missing stamp, or newer invalidating file returns all targets.
def files_needing_processing(stamp, target_files, invalidating_files)
  return target_files if Rake.application.options.build_all || !File.exist?(stamp)

  stamp_mtime = File.mtime(stamp)
  return target_files if invalidating_files.any? { |file| File.mtime(file) > stamp_mtime }

  target_files.select { |file| File.mtime(file) > stamp_mtime }
end

namespace :ruby do
  Rake::TestTask.new(:test) do |t|
    t.pattern = "test/**/*_test.rb"
  end

  desc "Run RuboCop to lint Ruby code"
  RuboCop::RakeTask.new(:rubocop) do |t|
    t.patterns = RUBY_RUBOCOP_TARGETS
  end
  Rake::Task[:rubocop].enhance([ RAKE_DIR ]) do
    touch RUBY_RUBOCOP_STAMP
  end
  class << Rake::Task[:rubocop]
    def needed?
      not_needed =
        files_needing_processing(
          RUBY_RUBOCOP_STAMP,
          FileList[*RUBY_RUBOCOP_TARGETS],
          %w[Rakefile .rubocop.yml]
        ).empty?
      not not_needed
    end
  end

  desc "Run all Ruby checks for CI (RuboCop -> Test)"
  task ci: %i[rubocop test]

  desc "Run Ruby unit tests and measure coverage (output: coverage/ruby/)"
  task :coverage do
    ENV["COVERAGE"] = "true"
    Rake::Task["ruby:test"].invoke
  end

  namespace :test do
    desc "Update golden master fixtures using the actual pmrails-init command"
    task :update_golden_master do
      require "tmpdir"
      require_relative "lib/pmrails"

      expected_dir = File.expand_path("test/ruby/fixtures/expected", __dir__)
      original_dir = File.expand_path("test/ruby/fixtures/original", __dir__)
      pmrails_init_bin = File.expand_path("bin/pmrails-init", __dir__)

      Dir.mktmpdir do |tmp_dir|
        puts "Updating Golden Masters in #{tmp_dir} ..."
        PmRails::SUPPORTED_DATABASES.each do |db|
          puts "  -> Generating for #{db}..."
          work_dir = File.join(tmp_dir, db)
          FileUtils.mkdir_p(File.join(work_dir, "test"))
          sys_test_path = File.join(work_dir, "test/application_system_test_case.rb")
          FileUtils.cp(File.join(original_dir, "application_system_test_case.rb"), sys_test_path)
          Dir.chdir(work_dir) do
            sh(pmrails_init_bin, "-d", db)
          end

          db_expected_dir = File.join(expected_dir, db)
          FileUtils.mkdir_p(db_expected_dir)
          FileUtils.cp(File.join(work_dir, ".pmrails/compose.yaml"), File.join(db_expected_dir, "compose.yaml"))
          FileUtils.cp(File.join(work_dir, ".pmrails/Dockerfile"), File.join(db_expected_dir, "Dockerfile"))

          if PmRails::SUPPORTED_DATABASES.first == db
            FileUtils.cp(sys_test_path, File.join(expected_dir, "application_system_test_case.rb.expected"))
          end
        end
      end

      puts "Golden Masters updated successfully!"
      puts "Please use `git diff` to verify the changes before committing."
    end
  end
end

TOOL_INSTALL_HINTS = {
  "git" => "sudo apt install git",
  "bats" => "sudo apt install bats",
  "shellcheck" => "sudo apt install shellcheck",
  "shfmt" => "sudo apt install shfmt",
  "editorconfig-checker" => 'sudo apt install -y golang && export PATH="$HOME/go/bin:$PATH" && go install github.com/editorconfig-checker/editorconfig-checker/v3/cmd/editorconfig-checker@latest',
  "kcov" => "See https://github.com/SimonKagstrom/kcov"
}.freeze
SHELL_LIB_FILE_GLOB = "lib/*.sh"
SHELL_LIBS = FileList[SHELL_LIB_FILE_GLOB]
SHELL_PRODUCTION_FILE_GLOBS = [
  "bin/pmrails-*",
  PRE_COMMIT_HOOK_SOURCE,
  "share/entrypoint",
  SHELL_LIB_FILE_GLOB
].freeze
SHELL_TEST_BASH_GLOB = "test/bats/*.bash"
SHELL_TEST_BATS_GLOB = "test/bats/*.bats"
SHELL_TEST_FILE_GLOBS = [
  SHELL_TEST_BASH_GLOB,
  SHELL_TEST_BATS_GLOB
].freeze
SHELL_SOURCE_FILE_GLOBS = (SHELL_PRODUCTION_FILE_GLOBS + SHELL_TEST_FILE_GLOBS).freeze
SHELL_TEST_HELPER_FILES = FileList[SHELL_TEST_BASH_GLOB]
SHELL_TEST_FILES = FileList[SHELL_TEST_BATS_GLOB]
SHELL_TEST_STAMP = "#{RAKE_DIR}/shell_test.stamp"
SHELL_LINT_STAMP = "#{RAKE_DIR}/shell_lint.stamp"
SHELL_COVERAGE_DIR = "coverage/shell"

# Returns tracked and non-ignored untracked shell source files.
#
# Using git ls-files excludes ignored files such as editor backups
# (for example, bin/pmrails-compose~) from linting and formatting.
def shell_source_files
  @shell_source_files ||= begin
    ensure_command!("git")
    # --cached:           Includes tracked files (default)
    # --others:           Includes untracked files
    # --exclude-standard: Excludes files matching .gitignore and .git/info/exclude
    out, err, status = Open3.capture3(
      "git", "ls-files", "-z",
      "--cached", "--others", "--exclude-standard",
      "--", *SHELL_SOURCE_FILE_GLOBS
    )
    unless status.success?
      abort("[Error] `git ls-files` failed (exit #{status.exitstatus}).\n#{err}")
    end
    files = out.split("\x00").select { |file| File.file?(file) }
    abort("[Error] No shell source files matched (#{SHELL_SOURCE_FILE_GLOBS.join(", ")}).") if files.empty?
    files
  end
end

# Validates an external task dependency before it is invoked.
#
# Only executable files on PATH qualify; shell aliases and functions do not.
# Missing tools produce a consistent error with an installation hint when known.
def ensure_command!(cmd)
  found = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
    path = File.join(dir, cmd)
    File.file?(path) && File.executable?(path)
  end
  return cmd if found

  msg = "[Error] Required command `#{cmd}` is not installed."
  hint = TOOL_INSTALL_HINTS[cmd]
  msg += "\nInstall hint: #{hint}" if hint
  abort(msg)
end

namespace :text do
  desc "Check text files against EditorConfig and Git whitespace rules"
  task :check do
    sh ensure_command!("editorconfig-checker")
    ensure_command!("git")
    sh 'git diff --check "$(git hash-object -t tree /dev/null)"'
  end
end

namespace :dev do
  namespace :hooks do
    desc "Install the optional pre-commit hook"
    task :install do
      ensure_command!("git")

      configured_hooks_path, err, status = Open3.capture3("git", "config", "--get", "core.hooksPath")
      if status.success?
        abort(<<~MESSAGE)
          [Error] core.hooksPath is already configured as #{configured_hooks_path.chomp.inspect}. It was not modified.
          To enable PmRails checks, add `rake ci` to your existing hooks manually.
        MESSAGE
      end
      abort("[Error] Could not inspect core.hooksPath.\n#{err}") unless status.exitstatus == 1

      hook_path, err, status = Open3.capture3("git", "rev-parse", "--git-path", "hooks/pre-commit")
      abort("[Error] Could not resolve the pre-commit hook path.\n#{err}") unless status.success?

      hook_path = hook_path.strip
      if File.exist?(hook_path) || File.symlink?(hook_path)
        abort(<<~MESSAGE)
          [Error] A pre-commit hook already exists at #{hook_path}. It was not modified.
          To enable PmRails checks, add `rake ci` to the existing hook manually.
        MESSAGE
      end

      FileUtils.mkdir_p(File.dirname(hook_path))
      FileUtils.install(File.expand_path(PRE_COMMIT_HOOK_SOURCE, __dir__), hook_path, mode: 0o755)
      puts "Installed pre-commit hook at #{hook_path}"
    end
  end
end

namespace :shell do
  desc "Run shell script checks for CI (Lint -> Format Check -> Test)"
  task ci: %i[lint format test]

  desc "Run shell script tests with bats"
  task test: [ RAKE_DIR ] do
    bats_files = files_needing_processing(
      SHELL_TEST_STAMP,
      SHELL_TEST_FILES,
      %w[Rakefile] + SHELL_LIBS + SHELL_TEST_HELPER_FILES
    )
    unless bats_files.empty?
      sh ensure_command!("bats"), *bats_files
      touch SHELL_TEST_STAMP
    end
  end

  desc "Measure shell script test coverage with kcov (output: coverage/shell/)"
  task :coverage do
    kcov_cmd = ensure_command!("kcov")
    bats_cmd = ensure_command!("bats")
    rm_rf SHELL_COVERAGE_DIR
    mkdir_p SHELL_COVERAGE_DIR
    include_dirs = SHELL_PRODUCTION_FILE_GLOBS.map { |g| File.expand_path(File.dirname(g)) }.uniq
    sh kcov_cmd, "--include-path=#{include_dirs.join(",")}", SHELL_COVERAGE_DIR, bats_cmd, *SHELL_TEST_FILES
  end

  desc "Lint shell scripts with shellcheck"
  task lint: [ RAKE_DIR ] do
    files = files_needing_processing(
      SHELL_LINT_STAMP,
      shell_source_files,
      %w[Rakefile]
    )
    unless files.empty?
      sh ensure_command!("shellcheck"), *files
      touch SHELL_LINT_STAMP
    end
  end

  desc "Check shell script formatting with shfmt (use shell:format:fix to apply)"
  task :format do
    sh ensure_command!("shfmt"), "-d", *shell_source_files
  end

  namespace :format do
    desc "Apply shfmt formatting in-place to shell scripts"
    task :fix do
      sh ensure_command!("shfmt"), "-w", *shell_source_files
    end
  end
end

task test: %i[ruby:test shell:test]
task ci: %i[text:check ruby:ci shell:ci]
task default: :ci
