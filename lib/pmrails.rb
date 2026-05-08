# frozen_string_literal: true

require "fileutils"
require "yaml"
require "thor"
require "active_support"
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/string/indent"


class DatabasePreset
  AptPackagePreset = Struct.new(:type, :packages)
  attr_reader :username, :password, :url_scheme, :volume_name, :compose_service
  attr_reader :apt_package_preset

  def initialize(database_option)
    @database_option = database_option
    assign_credentials
    assign_url_scheme
    assign_volume_name
    assign_compose_service
    assign_apt_package_preset
  end

  private
    def assign_credentials
      credentials =
        case @database_option
        when "postgresql"
          [ "postgres", "postgres" ]
        when "mysql", "trilogy", "mariadb-mysql", "mariadb-trilogy"
          [ "root", nil ]
        end
      # If credentials == nil, then both of @username and @password are nil
      @username, @password = credentials
    end

    def assign_url_scheme
      @url_scheme =
        case @database_option
        when "postgresql" then "postgres"
        when "mysql", "mariadb-mysql" then "mysql2"
        when "trilogy", "mariadb-trilogy" then "trilogy"
        end
    end

    def assign_volume_name
      @volume_name =
        if "sqlite3" != @database_option
          "pmrails-#{@database_option}-data"
        end
    end

    def assign_compose_service
      base_config = {
        "image"=>nil,
        "volumes"=>nil,
        "environment"=>nil,
        "healthcheck"=>{
          "interval"=>"2s",
          "timeout"=>"5s",
          "retries"=>10
        }
      }
      specific_config =
        case @database_option
        when "postgresql"
          {
            "shm_size"=>"128mb",
            "image"=>"postgres:17",
            "volumes"=>[ "#{volume_name}:/var/lib/postgresql/data" ],
            "environment"=>{
              "POSTGRES_USER"=>username,
              "POSTGRES_PASSWORD"=>password
            },
            "healthcheck"=>{
              "test"=>[ "CMD", "pg_isready", "-U", username ]
            }
          }
        when "mysql", "trilogy"
          {
            "image" => "mysql/mysql-server:8.0",
            "volumes"=>[ "#{volume_name}:/var/lib/mysql" ],
            "environment" => {
              "MYSQL_ALLOW_EMPTY_PASSWORD" => "true",
              "MYSQL_ROOT_HOST" => "%"
            },
            "healthcheck"=>{
              "test"=>[ "CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-u", username ]
            }
          }
        when "mariadb-mysql", "mariadb-trilogy"
          {
            "image" => "mariadb:11",
            "volumes"=>[ "#{volume_name}:/var/lib/mysql" ],
            "environment" => {
              "MARIADB_ALLOW_EMPTY_ROOT_PASSWORD" => "true"
            },
            "healthcheck"=>{
              "test"=>[ "CMD", "healthcheck.sh", "--connect", "--innodb_initialized" ]
            }
          }
        end
      if specific_config
        @compose_service = base_config.deep_merge(specific_config)
      end
    end

    def assign_apt_package_preset
      @apt_package_preset =
        case @database_option
        when "sqlite3"
          AptPackagePreset.new("SQLite3", %w[libsqlite3-dev sqlite3])
        when "postgresql"
          AptPackagePreset.new("PostgreSQL", %w[libpq-dev postgresql-client])
        when "mysql", "trilogy", "mariadb-mysql", "mariadb-trilogy"
          AptPackagePreset.new("MySQL / MariaDB", %w[default-libmysqlclient-dev default-mysql-client])
        end
    end
end

class PmRails < Thor
  include Thor::Actions
  SUPPORTED_DATABASES = %w[mysql trilogy postgresql sqlite3 mariadb-mysql mariadb-trilogy].freeze
  CONFLICT_COPY_SUFFIX = ".pmrails-init"
  DATABASE_SERVICE_NAME = "db"

  def self.exit_on_failure?
    true
  end

  def self.source_root
    File.dirname(__FILE__)
  end

  def self.basename
    "pmrails"
  end

  no_commands do
    def copy_file_preserving_existing(source, destination)
      destination_path = ::File.expand_path(destination, destination_root)
      if File.exist?(destination_path)
        source_path = ::File.expand_path(find_in_source_paths(source))
        if identical?(source_path, destination_path)
          say_status :identical, destination, :blue
        else
          copy_file(source, destination + CONFLICT_COPY_SUFFIX)
        end
      else
        copy_file(source, destination)
      end
    end

    def template_preserving_existing(source, destination)
      destination_path = ::File.expand_path(destination, destination_root)
      if File.exist?(destination_path)
        conflict_copy_destination = destination + CONFLICT_COPY_SUFFIX
        template(source, conflict_copy_destination, force: true)
        if identical?(destination_path, destination_path + CONFLICT_COPY_SUFFIX)
          say_status :identical, destination, :blue
          remove_file(conflict_copy_destination)
        end
      else
        template(source, destination)
      end
    end

    def patch_application_system_test_case
      sys_test_path = File.expand_path "test/application_system_test_case.rb", destination_root
      return unless File.exist? sys_test_path
      return if file_match? sys_test_path, /\bbrowser\b\W*\bremote\b/

      gsub_file(sys_test_path, /^\s*driven_by\b.*/, system_test_config)
    end
  end

  desc "init", "Create setting files for PmRails"
  method_option :database, type: :string, default: "sqlite3", aliases: "-d",
                enum: SUPPORTED_DATABASES,
                desc: "Preconfigure for selected database"
  def init
    @database_preset = DatabasePreset.new(options[:database])

    empty_directory ".pmrails"
    copy_file_preserving_existing "templates/init/config", ".pmrails/config"
    template_preserving_existing "templates/init/Dockerfile", ".pmrails/Dockerfile"
    template_preserving_existing "templates/init/compose.yaml", ".pmrails/compose.yaml"
    patch_application_system_test_case
  end

  private
    def identical?(file_a, file_b)
      FileUtils.cmp(file_a, file_b)
    end

    def file_match?(path, pattern)
      File.read(path).match?(pattern)
    end

    def database_package_type
      @database_preset.apt_package_preset.type
    end

    def database_packages
      @database_preset.apt_package_preset.packages
    end

    def database_url
      if url_scheme = @database_preset.url_scheme
        url_userinfo = [ @database_preset.username, @database_preset.password ].compact.join(":")
        "#{url_scheme}://#{url_userinfo}@#{DATABASE_SERVICE_NAME}/"
      end
    end

    def database_service_yaml_fragment
      if compose_service = @database_preset.compose_service
        { DATABASE_SERVICE_NAME=>compose_service }.to_yaml.sub(/\A---\r?\n/, "").indent(2)
      end
    end

    def compose_volume_names
      return @compose_volume_names if @compose_volume_names
      @compose_volume_names = []
      if volume_name = @database_preset.volume_name
        @compose_volume_names << volume_name
      end
      @compose_volume_names
    end

    def service_dependencies
      return @service_dependencies if @service_dependencies
      @service_dependencies = [ "selenium: {condition: service_healthy}" ]
      @service_dependencies << "#{DATABASE_SERVICE_NAME}: {condition: service_healthy}" if @database_preset.compose_service
      @service_dependencies
    end

    def system_test_config
      <<~'RUBY'.indent(2).chomp
        if ENV["CAPYBARA_SERVER_PORT"]
          served_by host: "rails-app", port: ENV["CAPYBARA_SERVER_PORT"]

          driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ], options: {
            browser: :remote,
            url: "http://#{ENV["SELENIUM_HOST"]}:4444"
          }
        else
          driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
        end
      RUBY
    end
end

if __FILE__ == $0
  argv = ARGV.difference(%w[-h --help])
  argv.unshift("help") if argv.length != ARGV.length
  PmRails.start(argv)
end
