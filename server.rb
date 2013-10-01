require 'sinatra'
require 'json'
require 'gyoku'
require 'haml'

def read_all_dependents
  '#-_abcdefghijklmnopqrstuvwxyz'.each_char.inject({}) do |data, char|
    data.merge!(JSON.parse(File.read("db/#{char}.json")))
  end
end

configure do
  set :dependents, read_all_dependents
  set :last_updated, File.mtime('db/#.json')
end

helpers do
  def dependents
    settings.dependents
  end

  def last_updated
    settings.last_updated
  end

  def hash_for_gem(gem_name)
    {
      'name' => gem_name,
      'version' => dependents[gem_name]['version'],
      'status' => dependents.include?(gem_name) ? 'ok' : 'not found',
      'last_updated' => last_updated.utc,
      'dependents' => dependents[gem_name]['dependents']
    }
  end
end

get '/' do
  haml :default
end

get %r{^/([\w\-]*)(?:\.json)?$} do |gem_name|
  content_type :json
  hash_for_gem(gem_name).to_json
end

get %r{^/([\w\-]*)(?:\.xml)?$} do |gem_name|
  content_type :xml
  Gyoku.xml(:gem => hash_for_gem(gem_name))
end

get %r{^/([\w\-]*)\.html$} do |gem_name|
  content_type :html

  @gem_name = gem_name

  if dependents.include?(gem_name)
    gem_data = dependents[gem_name]

    @last_updated = last_updated
    @version      = gem_data['version']
    @dependents   = gem_data['dependents']
    @description  = gem_data['description']

    haml :dependents

  else
    haml :gem_not_found
  end
end
