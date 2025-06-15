#!/usr/bin/env ruby

require_relative 'lib/tapsilat/version'
require 'fileutils'

class ReleaseManager
  VERSION_FILE = 'lib/tapsilat/version.rb'.freeze
  GEMSPEC_FILE = 'tapsilat.gemspec'.freeze

  def self.run(version_type = 'patch')
    new.release(version_type)
  end

  def release(version_type)
    puts '🚀 Starting release process...'

    current_version = Tapsilat::VERSION
    puts "📋 Current version: #{current_version}"

    new_version = increment_version(current_version, version_type)
    puts "📈 New version: #{new_version}"

    update_version_file(new_version)
    commit_changes(new_version)
    build_and_push_gem
    cleanup

    puts '✅ Release completed successfully!'
    puts "🎉 tapsilat #{new_version} is now live on RubyGems!"
  end

  private

  def increment_version(version, type)
    major, minor, patch = version.split('.').map(&:to_i)

    case type.downcase
    when 'major'
      "#{major + 1}.0.0"
    when 'minor'
      "#{major}.#{minor + 1}.0"
    when 'patch', 'p'
      "#{major}.#{minor}.#{patch + 1}"
    else
      raise "Invalid version type: #{type}. Use 'major', 'minor', or 'patch'"
    end
  end

  def update_version_file(new_version)
    puts '📝 Updating version file...'
    content = File.read(VERSION_FILE)
    updated_content = content.gsub(/VERSION = '[^']*'/, "VERSION = '#{new_version}'")
    File.write(VERSION_FILE, updated_content)
  end

  def commit_changes(new_version)
    puts '📦 Committing changes...'
    system("git add #{VERSION_FILE}")
    system("git commit -m 'Bump version to #{new_version}'")
    system("git tag v#{new_version}")
    puts "🏷️  Tagged as v#{new_version}"
  end

  def build_and_push_gem
    puts '🔨 Building gem...'
    system("gem build #{GEMSPEC_FILE}")

    gem_file = "tapsilat-#{current_version}.gem"

    puts '🚀 Pushing to RubyGems...'
    system("gem push #{gem_file}")
  end

  def cleanup
    puts '🧹 Cleaning up...'
    gem_file = "tapsilat-#{current_version}.gem"
    FileUtils.rm_f(gem_file)
  end

  def current_version
    # Read version directly from file to avoid constant redefinition warning
    content = File.read(VERSION_FILE)
    version_match = content.match(/VERSION = '([^']*)'/)
    version_match[1] if version_match
  end
end

# Script kullanımı
if __FILE__ == $PROGRAM_NAME
  version_type = ARGV[0] || 'patch'

  puts <<~USAGE
    🎯 Tapsilat Gem Release Manager

    Usage: ruby release.rb [version_type]

    Version types:
    - patch (default): 0.1.3 -> 0.1.4
    - minor: 0.1.3 -> 0.2.0#{'  '}
    - major: 0.1.3 -> 1.0.0

    Current command: ruby release.rb #{version_type}

  USAGE

  puts 'Press Enter to continue or Ctrl+C to cancel...'
  $stdin.gets

  ReleaseManager.run(version_type)
end
