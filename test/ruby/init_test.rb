# frozen_string_literal: true

require_relative "./test_helper"
require "fileutils"
require "securerandom"
require "tmpdir"
require_relative "../../lib/pmrails"

module Minitest::Assertions
  def assert_file_equal(expected_path, actual_path, msg = nil)
    unless File.exist?(expected_path)
      raise ArgumentError, "Test Setup Error: Expected file not found at #{expected_path}"
    end
    assert_path_exists actual_path, msg

    expected_content = File.read(expected_path)
    actual_content   = File.read(actual_path)

    error_msg = message(msg) do
      diff_text = diff(expected_content, actual_content)
      "File contents mismatch!\n" \
      "Expected file: #{expected_path}\n" \
      "Actual file  : #{actual_path}\n" \
      "#{diff_text}"
    end

    assert expected_content == actual_content, error_msg
  end
end

class PmRailsInitTest < Minitest::Test
  INIT_TEMPLATES_DIR = File.expand_path("../../lib/templates/init", __dir__)
  EXPECTED_FIXTURES_DIR = File.expand_path("fixtures/expected", __dir__)
  ORIGINAL_FIXTURES_DIR = File.expand_path("fixtures/original", __dir__)

  PmRails::SUPPORTED_DATABASES.each do |db|
    define_method("test_fresh_init_for_#{db.tr('-', '_')}") do
      with_sandbox(db_tag(db)) do
        start_pmrails_init(db)
        assert_file_equal File.join(INIT_TEMPLATES_DIR, "config"),     ".pmrails/config"
        assert_file_equal File.join(EXPECTED_FIXTURES_DIR, db, "Dockerfile"), ".pmrails/Dockerfile"
        assert_file_equal File.join(EXPECTED_FIXTURES_DIR, db, "compose.yaml"), ".pmrails/compose.yaml"
      end
    end
  end

  def test_conflict_preserves_existing_files
    db = PmRails::SUPPORTED_DATABASES.sample
    with_sandbox(db_tag(db)) do
      custom_dockerfile_content = mock_user_content("USER_CUSTOM_DOCKERFILE")
      custom_config_content = mock_user_content("USER_CUSTOM_CONFIG")
      custom_compose_content = mock_user_content("USER_CUSTOM_COMPOSE")

      FileUtils.mkdir_p(".pmrails")
      File.write(".pmrails/Dockerfile", custom_dockerfile_content)
      File.write(".pmrails/config", custom_config_content)
      File.write(".pmrails/compose.yaml", custom_compose_content)

      start_pmrails_init(db)

      assert_equal custom_dockerfile_content, File.read(".pmrails/Dockerfile")
      assert_equal custom_config_content, File.read(".pmrails/config")
      assert_equal custom_compose_content, File.read(".pmrails/compose.yaml")

      assert_file_equal File.join(INIT_TEMPLATES_DIR, "config"),     ".pmrails/config.pmrails-init"
      assert_file_equal File.join(EXPECTED_FIXTURES_DIR, db, "Dockerfile"), ".pmrails/Dockerfile.pmrails-init"
      assert_file_equal File.join(EXPECTED_FIXTURES_DIR, db, "compose.yaml"), ".pmrails/compose.yaml.pmrails-init"
    end
  end

  def test_patches_system_test_case
    db = PmRails::SUPPORTED_DATABASES.sample
    with_sandbox(db_tag(db)) do
      FileUtils.mkdir_p("test")
      original_file = File.join(ORIGINAL_FIXTURES_DIR, "application_system_test_case.rb")
      FileUtils.cp(original_file, "test/application_system_test_case.rb")

      start_pmrails_init(db)
      assert_file_equal File.join(EXPECTED_FIXTURES_DIR, "application_system_test_case.rb.expected"), "test/application_system_test_case.rb"

      start_pmrails_init(db)
      assert_file_equal File.join(EXPECTED_FIXTURES_DIR, "application_system_test_case.rb.expected"), "test/application_system_test_case.rb"
    end
  end

  private
    def db_tag(db)
      "[DB: #{db}] "
    end

    def with_sandbox(tag = nil)
      Dir.mktmpdir do |tmp_dir|
        Dir.chdir(tmp_dir) do
          yield
        end
      end
    rescue Minitest::Assertion, StandardError => e
      raise e.exception("#{tag}#{e.message}")
    end

    def start_pmrails_init(db)
      capture_io { PmRails.start([ "init", "-d", db ]) }
    end

    def mock_user_content(label)
      "#{label};Timestamp(#{Time.now.inspect});Rand(#{SecureRandom.base64(8)})"
    end
end
