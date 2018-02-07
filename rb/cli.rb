#!/usr/bin/env ruby

require 'json'
require 'ostruct'
require 'optparse'

require 'bundler'
Bundler.require(:default)

@config = OpenStruct.new(
  id_len: 6,
  title_len: 60,
  debug: false,
  gitlab_url: ENV.fetch('GITLAB_API_URL', 'http://gitlab.com'),
  gitlab_key: ENV.fetch('GITLAB_API_KEY')
)
ID_LEN = 6
TITLE_LEN = 60
DEBUG = false

@options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: cli.rb [options]"

  opts.on("-l", "--labels [LABEL, (label)...]", Array) do |l|
    @options[:labels] = l
  end
end.parse!

@connection =
  Faraday.new(url: @config.gitlab_url) do |f|
    f.request  :url_encoded             # form-encode POST params
    f.response :logger if DEBUG         # log requests to STDOUT
    f.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  end

def api_get(url, params = {}, headers = {})
  auth_header = { 'Private-Token': @config.gitlab_key }
  @connection.get do |req|
    req.url url
    req.params.merge! params
    req.headers.merge! headers.merge(auth_header)
  end
end

params = { scope: 'assigned-to-me', labels: [*@options[:labels]].join(',') }
response = api_get '/api/v4/issues', params

JSON.parse(response.body, object_class: OpenStruct).each do |issue|
  puts sprintf "%-#{ID_LEN}s\t%-#{TITLE_LEN}s\n",
    issue.id, issue.title[0..TITLE_LEN]
end
