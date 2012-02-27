require "sinatra"
require "json"
require "haml"

configure do
  set :dependents, JSON.parse(File.read("dependents.json"))
  set :last_updated, File.mtime("dependents.json")
end

helpers do
  def dependents
    settings.dependents
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
    :last_updated => last_updated.utc,
    :dependents => dependents[gem_name]
  }.to_json
end

get %r{^/([\w\-]*)\.html$} do |gem_name|
  content_type :html

  @gem_name = gem_name
  @last_updated = last_updated
  @dependents = dependents[gem_name] || []
  haml :dependents
end