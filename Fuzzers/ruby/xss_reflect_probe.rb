#!/usr/bin/env ruby
# xss_reflect_probe.rb — inject payloads into one query/body param; report reflection.
# authorized targets only · dntaskmehow
# Usage: ruby xss_reflect_probe.rb -u 'https://yourtarget.com/search' -p q -f xss_payloads.txt

require "net/http"
require "uri"
require "json"
require "openssl"
require "optparse"

CANARY = "XSSCANARY"

def load_payloads(path)
  return [CANARY, "\"><img src=x onerror=#{CANARY}>"] unless path && File.file?(path)

  File.readlines(path, chomp: true).filter_map do |line|
    next if line.strip.empty? || line.start_with?("#")

    line.gsub("XSSCANARY", CANARY)
  end
end

def build_uri(base, param, value, method)
  uri = URI(base)
  q = URI.decode_www_form(uri.query || "").to_h
  q[param] = value
  uri.query = URI.encode_www_form(q)
  uri
end

def post_body(param, value)
  URI.encode_www_form([[param, value]])
end

def fetch(uri, method:, headers:, timeout:, param:, value:)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  http.open_timeout = timeout
  http.read_timeout = timeout
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ENV["INSECURE_TLS"] == "1"

  req = method == "POST" ? Net::HTTP::Post.new(uri.request_uri) : Net::HTTP::Get.new(uri.request_uri)
  headers.each { |k, v| req[k] = v }
  if method == "POST"
    req["Content-Type"] = "application/x-www-form-urlencoded"
    req.body = post_body(param, value)
  end
  http.request(req)
end

def classify_reflection(body, needle)
  return :none unless body.include?(needle)

  if body.include?("<script") && body.include?(needle)
    :in_script_context
  elsif body.match?(/<[^>]+['"][^'"]*#{Regexp.escape(needle)}/)
    :in_attribute_context
  elsif body.include?(CGI.escapeHTML(needle)) && !body.include?(needle)
    :html_encoded
  elsif body.include?(needle)
    :raw_reflection
  else
    :unknown
  end
end

options = {
  method: "GET",
  timeout: 15,
  delay: 0.0,
  headers: {
    "User-Agent" => "BountyTools-XSS-Probe/1.0 (authorized testing)",
    "Accept" => "text/html,application/xhtml+xml,application/json;q=0.9,*/*;q=0.8"
  }
}

parser = OptionParser.new do |o|
  o.banner = "Usage: #{File.basename($PROGRAM_NAME)} -u URL -p PARAM [options]"
  o.on("-u", "--url URL", "Full URL with or without query string") { |v| options[:url] = v }
  o.on("-p", "--param NAME", "Parameter to inject") { |v| options[:param] = v }
  o.on("-f", "--file PATH", "Payload file (default: xss_payloads.txt beside this script)") { |v| options[:file] = v }
  o.on("-m", "--method METHOD", "GET or POST") { |v| options[:method] = v.upcase }
  o.on("--json", "Emit JSON lines") { options[:json] = true }
  o.on("--delay SEC", Float, "Sleep between requests") { |v| options[:delay] = v }
  o.on("-t", "--timeout SEC", Integer, "HTTP timeout") { |v| options[:timeout] = v }
  o.on("-h", "--help", "Help") { puts o; exit 0 }
end
parser.parse!

abort "missing -u URL" unless options[:url]
abort "missing -p PARAM" unless options[:param]

payload_file = options[:file] || File.join(__dir__, "xss_payloads.txt")
payloads = load_payloads(payload_file)
@param = options[:param]

results = []

base_uri = URI(options[:url])

payloads.each_with_index do |payload, idx|
  uri = options[:method] == "GET" ? build_uri(options[:url], @param, payload, options[:method]) : base_uri

  begin
    res = fetch(
      uri,
      method: options[:method],
      headers: options[:headers],
      timeout: options[:timeout],
      param: @param,
      value: payload
    )
    body = res.body.to_s
    reflection = classify_reflection(body, CANARY)
    hit = reflection != :none

    row = {
      index: idx,
      payload: payload,
      status: res.code.to_i,
      length: body.bytesize,
      reflection: reflection.to_s,
      interesting: hit,
      url: uri.to_s
    }
    results << row

    if options[:json]
      puts JSON.generate(row)
    elsif hit
      puts "[+] #{reflection} | #{res.code} | #{payload[0, 80]}"
    else
      puts "[.] no reflection | #{res.code} | #{payload[0, 60]}"
    end
  rescue StandardError => e
    err = { index: idx, payload: payload, error: e.message }
    results << err
    puts "[!] #{e.message}" unless options[:json]
    puts JSON.generate(err) if options[:json]
  end

  sleep(options[:delay]) if options[:delay].positive?
end

unless options[:json]
  hits = results.count { |r| r[:interesting] }
  puts "\n[*] #{hits}/#{payloads.size} payloads reflected canary (#{CANARY})"
  puts "[*] Manual step: confirm HTML context and impact on authorized target only."
end