require 'uri'
require 'net/http'
require 'net/https'

module Asset extend self
  class ConnectionError < StandardError
    attr_reader :response

    def initialize(response, message = nil)
      @response = response
      @message  = message
    end

    def to_s
      message = "Failed."
      message << "  Response code = #{response.code}." if response.respond_to?(:code)
      message << "  Response message = #{response.message}." if response.respond_to?(:message)
      message
    end
  end

  class BadRequest < ConnectionError; end
  class Redirection < ConnectionError
    def to_s; response['Location'] ? "#{super} => #{response['Location']}" : super; end
  end

  def get(url)
    result = Tempfile.new("nfr.#{rand(1000)}")

    stream(url) do |io|
      io.read_body do |chunk|
        result.write(chunk)
      end
    end

    result.rewind
    result

  rescue Redirection => error
    get error.response['Location']
  end

  def stream(url)
    uri = URI.parse(url)

    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      throw URI::InvalidURIError
    end

    http   = Net::HTTP.new(uri.host, uri.port)
    method = Net::HTTP::Get.new(uri.path)

    if uri.is_a?(URI::HTTPS)
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.start do |stream|
      stream.request(method) do |response|
        handle_response(response)
        yield response
      end
    end
  end

  protected

  def handle_response(response)
    case response.code.to_i
    when 200...299
      response
    when 301,302
      raise Redirection.new(response)
    else
      raise BadRequest.new(response)
    end
  end
end