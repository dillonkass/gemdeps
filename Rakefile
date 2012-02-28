require "parallel"
require "httparty"

require File.join(File.dirname(__FILE__), "lib", "gem_dependencies")

desc "Update stored gem dependencies for all gems"
task :update do
  gem_dependencies = GemDependencies.new(`gem list --remote`.lines.map { |line| line.split(/\s+/) })

  Parallel.each(gem_dependencies, :in_threads => 16) do |gem_name|
    begin
      json = HTTParty.get("https://rubygems.org/api/v1/gems/#{gem_name}.json").body
      info = JSON.parse(json)
      puts "Adding dependencies for #{gem_name}..."
      gem_dependencies.read_dependencies(info)
    rescue
      # Oh well...
    end
  end

  gem_dependencies.save_to_file("dependents.json")
end

task :default => :update