require "json"
require "thread"

class GemDependencies
  def initialize(gem_names_and_versions)
    dependents_hash = {}
    gem_names_and_versions.each do |name, version|
      dependents_hash[name] = {
        :version => read_version(version),
        :dependents => []
      }
    end

    @dependents_hash = dependents_hash
    @mutex = Mutex.new
  end

  def to_a
    @dependents_hash.keys.to_a
  end

  def read_version(string)
    match = string.match(/\(([^\)]*)\)/)

    if match.nil?
      "unknown"
    else
      match[1]
    end
  end

  def read_dependencies(gem_info)
    return if not gem_info.include? "dependencies"

    dependent_gem_name = gem_info["name"]

    @mutex.synchronize do
      gem_info["dependencies"].each do |category, gems|
        gems.each do |gem|
          precedent_gem_name = gem["name"]
          requirements = gem["requirements"]

          if @dependents_hash.include? precedent_gem_name
            @dependents_hash[precedent_gem_name][:dependents] << {
              :name => dependent_gem_name,
              :requirements => requirements
            }
          end
        end
      end
    end
  end

  def delete_gems_without_dependents
    @dependents_hash.delete_if { |key, value| value[:dependents].empty? }
  end

  def save_to_file(file_name)
    File.open(file_name, "w").write(@dependents_hash.to_json)
  end
end
