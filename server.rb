require "sinatra"
require "json"
require "haml"

configure do
  set :dependencies, JSON.parse(File.read("dependencies.json"))
  set :last_updated, File.mtime("dependencies.json")
end

helpers do
  def dependencies
    settings.dependencies
  end

  def last_updated
    settings.last_updated
  end
end

get "/" do
  haml :default
end

get %r{^/([\w\-]*)(?:\.json)?$} do |gem_name|
  content_type :json

  {
    :gem => gem_name,
    :last_updated => last_updated,
    :dependencies => dependencies[gem_name]
  }.to_json
end

get %r{^/([\w\-]*)\.html$} do |gem_name|
  content_type :html

  @gem_name = gem_name
  @dependents = dependencies[gem_name]
  haml :dependents
end