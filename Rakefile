# frozen_string_literal: true

require "open3"
require "rake/testtask"
require "rubocop/rake_task"

namespace :ruby do
  Rake::TestTask.new(:test) do |t|
    t.pattern = "test/**/*_test.rb"
  end

  desc "Run RuboCop to lint Ruby code"
  RuboCop::RakeTask.new(:rubocop)

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
      require "fileutils"
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

SHELL_TOOL_INSTALL_HINTS = {
  "git" => "sudo apt install git",
  "bats" => "sudo apt install bats",
  "shellcheck" => "sudo apt install shellcheck",
  "shfmt" => "sudo apt install shfmt",
  "kcov" => "See https://github.com/SimonKagstrom/kcov"
}.freeze
SHELL_PRODUCTION_FILE_GLOBS = %w[
  bin/pmrails-*
  lib/*.sh
].freeze
SHELL_TEST_FILE_GLOBS = %w[
  test/bats/*.bash
  test/bats/*.bats
].freeze
SHELL_SOURCE_FILE_GLOBS = (SHELL_PRODUCTION_FILE_GLOBS + SHELL_TEST_FILE_GLOBS).freeze
SHELL_TEST_DIR = "test/bats"
SHELL_COVERAGE_DIR = "coverage/shell"

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
    files = out.split("\x00").reject(&:empty?)
    abort("[Error] No shell source files matched (#{SHELL_SOURCE_FILE_GLOBS.join(", ")}).") if files.empty?
    files
  end
end

def ensure_command!(cmd)
  found = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
    path = File.join(dir, cmd)
    File.file?(path) && File.executable?(path)
  end
  return cmd if found

  msg = "[Error] Required command `#{cmd}` is not installed."
  hint = SHELL_TOOL_INSTALL_HINTS[cmd]
  msg += "\nInstall hint: #{hint}" if hint
  abort(msg)
end

namespace :shell do
  desc "Run shell script checks for CI (Lint -> Format Check -> Test)"
  task ci: %i[lint format test]

  desc "Run shell script tests with bats"
  task :test do
    sh ensure_command!("bats"), SHELL_TEST_DIR
  end

  desc "Measure shell script test coverage with kcov (output: coverage/shell/)"
  task :coverage do
    kcov_cmd = ensure_command!("kcov")
    bats_cmd = ensure_command!("bats")
    rm_rf SHELL_COVERAGE_DIR
    mkdir_p SHELL_COVERAGE_DIR
    include_dirs = SHELL_PRODUCTION_FILE_GLOBS.map { |g| File.expand_path(File.dirname(g)) }.uniq
    sh kcov_cmd, "--include-path=#{include_dirs.join(",")}", SHELL_COVERAGE_DIR, bats_cmd, SHELL_TEST_DIR
  end

  desc "Lint shell scripts with shellcheck"
  task :lint do
    sh ensure_command!("shellcheck"), *shell_source_files
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
task ci: %i[ruby:ci shell:ci]
task default: :ci
