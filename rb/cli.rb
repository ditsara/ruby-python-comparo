#!/usr/bin/env ruby

require 'json'
require 'ostruct'
require 'optparse'

require 'bundler'
Bundler.require(:default)

def config
  OpenStruct.new(
    id_len: 6,
    title_len: 60,
    debug: false,
    gitlab_url: ENV.fetch('GITLAB_API_URL', 'http://gitlab.com'),
    gitlab_key: ENV.fetch('GITLAB_API_KEY')
  )
end

def options
  @options ||=
    begin
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: cli.rb [options]"

        opts.on("-l", "--labels [LABEL, (label)...]") do |l|
          options[:labels] = l
        end
      end.parse!

      options
    end
end

def connection
  @connection ||=
    begin
      Faraday.new(url: config.gitlab_url) do |f|
        f.request  :url_encoded             # form-encode POST params
        f.response :logger if config.debug  # log requests to STDOUT
        f.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end
end

def api_get(url, params = {}, headers = {})
  auth_header = { 'Private-Token': config.gitlab_key }
  connection.get do |req|
    req.url url
    req.params.merge! params
    req.headers.merge! headers.merge(auth_header)
  end
end

def run
  params = { scope: 'assigned-to-me', labels: options[:labels] }
  response = api_get '/api/v4/issues', params

  JSON.parse(response.body, object_class: OpenStruct).each do |issue|
    puts sprintf "%-#{config.id_len}s\t%-#{config.title_len}s\n",
      issue.id, issue.title[0..config.title_len]
  end
end

run if __FILE__ == $0
