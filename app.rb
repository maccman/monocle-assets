require 'sinatra'
require 'mini_magick'

configure do
  enable :use_code
  set :show_exceptions, :after_handler
end

helpers do
  def validate_url!(url)
    URI.parse("http://#{ url }")
  rescue
    error 422
  end
end

error SocketError, MiniMagick::Invalid do
  406
end

get '/resize/:dimensions/*' do |dimensions, url|
  validate_url!(url)

  image = MiniMagick::Image.open("http://#{ url }")
  image.combine_options do |command|
    command.filter('box')
    command.resize(dimensions)
  end

  send_file(image.path, :disposition => 'inline')
end

get '/crop/:dimensions/*' do |dimensions, url|
  validate_url!(url)

  image = MiniMagick::Image.open("http://#{ url }")
  image.combine_options do |command|
    command.filter('box')
    command.resize(dimensions + '^^')
    command.gravity('Center')
    command.extent(dimensions)
  end

  send_file(image.path, :disposition => 'inline')
end