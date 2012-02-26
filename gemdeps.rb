require "parallel"
require "httparty"
require "json"
require "thread"

class GemDependencies
  def initialize(gem_names)
    dependents_hash = {}
    gem_names.each do |gem_name|
      dependents_hash[gem_name] = []
    end

    @dependents_hash = dependents_hash
    @mutex = Mutex.new
  end

  def to_a
    @dependents_hash.keys.to_a
  end

  def to_hash
    @dependents_hash
  end

  def read_dependencies(gem_info)
    return if not gem_info.include? "dependencies"

    dependent_gem_name = gem_info["name"]

    gem_info["dependencies"].each do |category, gems|
      gems.each do |gem|
        precedent_gem_name = gem["name"]

        @mutex.synchronize do
          if @dependents_hash.include? precedent_gem_name
            puts "#{dependent_gem_name} is dependent on #{precedent_gem_name}."
            @dependents_hash[precedent_gem_name] << dependent_gem_name
          end
        end
      end
    end
  end

  def delete_gems_without_dependents
    @dependents_hash.delete_if { |key, value| value.empty? }
  end

  def save_to_file
    File.open("dependencies.json", "w").write(@dependents_hash.to_json)
  end
end

gem_dependencies = GemDependencies.new(`gem list --remote`.lines.map { |line| line.split(/\s+/)[0] })

Parallel.each(gem_dependencies, :in_threads => 4) do |gem_name|
    begin
      json = HTTParty.get("https://rubygems.org/api/v1/gems/#{gem_name}.json").body
      info = JSON.parse(json)
      puts "Adding dependencies for #{gem_name}..."
      gem_dependencies.read_dependencies(info)
    rescue
      # Oh well...
    end
end

gem_dependencies.delete_gems_without_dependents # just to save some space

gem_dependencies.save_to_file