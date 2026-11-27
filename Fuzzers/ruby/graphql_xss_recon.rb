#!/usr/bin/env ruby
# graphql_xss_recon.rb — homepage DOM hints + GraphQL introspection → JSON report.
# Authorized targets only · stdlib · dntaskmehow

require "net/http"
require "uri"
require "json"
require "openssl"
require "optparse"
require "time"

INTROSPECTION = '{"query":"{ __schema { queryType { name } types { name kind fields { name args { name type { name kind ofType { name kind ofType { name kind } } } } } inputFields { name } } } }"}'

def http_get(uri, timeout:, insecure:)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  http.open_timeout = timeout
  http.read_timeout = timeout
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE if insecure
  req = Net::HTTP::Get.new(uri.request_uri)
  req["User-Agent"] = "BountyTools-GraphQL-Recon/1.0"
  req["Accept"] = "text/html,application/json"
  http.request(req)
end

def http_post_json(uri, body, timeout:, insecure:)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  http.open_timeout = timeout
  http.read_timeout = timeout
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE if insecure
  req = Net::HTTP::Post.new(uri.request_uri)
  req["Content-Type"] = "application/json"
  req["Accept"] = "application/json"
  req["User-Agent"] = "BountyTools-GraphQL-Recon/1.0"
  req.body = body
  http.request(req)
end

def dom_reflection_hints(html)
  hints = []
  hints << { sink: "erb_value_attribute", selector: 'input[value*="<%="]', present: html.match?(/value\s*=\s*["'][^"']*<%=/) || html.include?('params[:search]') }
  hints << { sink: "json_parse_erb_string", present: html.match?(/JSON\.parse\s*\(\s*['"][^'"]*<%=/) }
  hints << { sink: "innerHTML_assignment", present: html.match?(/\.innerHTML\s*=/) }
  hints << { sink: "react_root", present: html.include?("id=\"app\"") || html.include?("id='app'") }
  hints.select { |h| h[:present] }
end

def string_graphql_arguments(schema)
  out = []
  types = schema.dig("data", "__schema", "types") || []
  types.each do |t|
    name = t["name"].to_s
    next if name.start_with?("__")
    (t["fields"] || []).each do |field|
      (field["args"] || []).each do |arg|
        if type_chain_includes?(arg["type"], "String")
          out << {
            parent_type: name,
            field: field["name"],
            argument: arg["name"],
            vector_hint: "Supply search/query via GraphQL; check if response fields (e.g. html, title) reach DOM sinks"
          }
        end
      end
    end
  end
  out
end

def type_chain_includes?(type_node, want)
  cur = type_node
  6.times do
    return false unless cur
    return true if cur["name"] == want
    cur = cur["ofType"]
  end
  false
end

def load_static_vectors(path)
  return [] unless path && File.file?(path)

  JSON.parse(File.read(path))
rescue JSON::ParserError
  []
end

options = {
  base: "https://yourtarget.com",
  out: "graphql_xss_recon.json",
  delay: 1.0,
  timeout: 20,
  insecure: false,
  payloads: File.join(__dir__, "payloads", "rails_graphql_dom_vectors.json")
}

OptionParser.new do |o|
  o.on("-b", "--base URL") { |v| options[:base] = v.delete_suffix("/") }
  o.on("-o", "--output FILE") { |v| options[:out] = v }
  o.on("-p", "--payloads FILE", "Static vector catalog JSON") { |v| options[:payloads] = v }
  o.on("--insecure", "Skip TLS verify (authorized broken-cert hosts)") { options[:insecure] = true }
  o.on("--delay SEC", Float) { |v| options[:delay] = v }
  o.on("-t", "--timeout SEC", Integer) { |v| options[:timeout] = v }
end.parse!

report = {
  base_url: options[:base],
  generated_at: Time.now.utc.iso8601,
  homepage: nil,
  graphql: nil,
  dom_sinks: [],
  graphql_string_inputs: [],
  recommended_vectors: []
}

base_uri = URI(options[:base])

begin
  res = http_get(base_uri, timeout: options[:timeout], insecure: options[:insecure])
  html = res.body.to_s
  report[:homepage] = { status: res.code.to_i, bytes: html.bytesize }
  report[:dom_sinks] = dom_reflection_hints(html)
rescue OpenSSL::SSL::SSLError => e
  report[:homepage] = { ssl_error: e.message, retried_insecure: false }
  if options[:insecure]
    report[:homepage][:retried_insecure] = true
  end
rescue StandardError => e
  report[:homepage] = { error: e.class.name, message: e.message }
end

sleep(options[:delay])

gql_attempts = []
schema = nil
%w[/graphql /api/graphql /api/v1/graphql].each do |path|
  uri = URI("#{options[:base]}#{path}")
  begin
    res = http_post_json(uri, INTROSPECTION, timeout: options[:timeout], insecure: options[:insecure])
    gql_attempts << { path: path, status: res.code.to_i }
    next unless res.code.to_i.between?(200, 299)

    body = JSON.parse(res.body)
    next unless body["data"]

    schema = body
    report[:graphql] = { path: path, status: res.code.to_i, introspection: true }
    report[:graphql_string_inputs] = string_graphql_arguments(schema)
    break
  rescue StandardError => e
    gql_attempts << { path: path, error: e.message }
  end
  sleep(options[:delay])
end

report[:graphql] ||= { introspection: false, attempts: gql_attempts }

raw_catalog = load_static_vectors(options[:payloads])
report[:recommended_vectors] = raw_catalog.is_a?(Hash) ? (raw_catalog["vectors"] || []) : raw_catalog

File.write(options[:out], JSON.pretty_generate(report))
puts options[:out]