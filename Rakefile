require 'json'
require 'parallel'
require 'httparty'

require File.join(File.dirname(__FILE__), 'lib', 'gem_dependencies')

def is_digit?(char)
  char >= '0' && char <= '9'
end

def first_char(str)
  char = str[0]

  # Group all numbers together
  return '#' if is_digit?(char)

  char.downcase
end

desc 'Alphabetize downloaded dependencies and store them in the db/ folder'
task :alphabetize do
  puts 'Reading dependents.json...'
  dependents = JSON.parse(File.read('dependents.json'))

  dependents.keys.group_by(&method(:first_char)).each do |char, gem_names|
    data = gem_names.inject({}) do |hash, gem_name|
      hash.merge!(gem_name => dependents[gem_name])
    end

    puts "Writing db/#{char}.json..."
    File.open("db/#{char}.json", 'w') do |f|
      f.write(JSON.pretty_generate(data))
    end
  end

  puts 'Done.'
end

desc 'Update stored gem dependencies for all gems'
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

  puts 'All gemdeps:'
  puts gem_dependencies.to_json

  print 'Saving... '; STDOUT.flush
  gem_dependencies.save_to_file('dependents.json')
  puts 'Done.'
end

task :default => :update
