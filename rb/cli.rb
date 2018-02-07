#!/usr/bin/env ruby

require 'json'
require 'ostruct'
require 'optparse'

require 'bundler'
Bundler.require(:default)

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
  Faraday.new(url: ENV.fetch('GITLAB_API_URL', 'http://gitlab.com')) do |f|
    f.request  :url_encoded             # form-encode POST params
    f.response :logger if DEBUG         # log requests to STDOUT
    f.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  end

def api_get(url, params = {}, headers = {})
  @connection.get do |req|
    req.url url
    req.params.merge! params
    req.headers.merge! headers
  end
end

headers = { 'Private-Token': ENV.fetch('GITLAB_API_KEY') }
params = { scope: 'assigned-to-me', labels: [*@options[:labels]].join(',') }
response = api_get '/api/v4/issues', params, headers

JSON.parse(response.body, object_class: OpenStruct).each do |issue|
  puts sprintf "%-#{ID_LEN}s\t%-#{TITLE_LEN}s\n",
    issue.id, issue.title[0..TITLE_LEN]
end
