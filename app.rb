require 'uri'
require 'sinatra'
require 'mini_magick'
require_relative 'lib/asset'

configure do
  enable :use_code
  set :show_exceptions, :after_handler
end

error URI::InvalidURIError do
  422
end

error SocketError, MiniMagick::Invalid do
  406
end

before do
  expires 31557600, :public, :max_age => 31536000
end

get '/mirror/*' do |url|
  content_type File.extname(url)
  send_file(Asset.get("http://#{ url }"), :disposition => 'inline')
end

get '/resize/:dimensions/*' do |dimensions, url|
  asset = Asset.get("http://#{ url }")

  image = MiniMagick::Image.open(asset.path)
  image.combine_options do |command|
    command.filter('box')
    command.resize(dimensions)
  end

  content_type File.extname(url)
  send_file(image.path, :disposition => 'inline')
end

get '/crop/:dimensions/*' do |dimensions, url|
  asset = Asset.get("http://#{ url }")

  image = MiniMagick::Image.open(asset.path)
  image.combine_options do |command|
    command.filter('box')
    command.resize(dimensions + '^^')
    command.gravity('Center')
    command.extent(dimensions)
  end

  content_type File.extname(url)
  send_file(image.path, :disposition => 'inline')
end