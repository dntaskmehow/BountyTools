#!/usr/bin/env ruby
# xss_encode_variants.rb — emit encoding variants for one base payload (stdin or -s).
# Use to test filters; pair with xss_reflect_probe.rb on authorized targets.
# Usage: echo '<img src=x onerror=1>' | ruby xss_encode_variants.rb

require "uri"
require "cgi"
require "optparse"

options = { base: nil }

OptionParser.new do |o|
  o.on("-s", "--string PAYLOAD", "Base payload string") { |v| options[:base] = v }
end.parse!

base = options[:base] || $stdin.read
base = base.strip
abort "empty payload" if base.empty?

variants = {
  raw: base,
  url: URI.encode_www_form_component(base),
  double_url: URI.encode_www_form_component(URI.encode_www_form_component(base)),
  html_entity: base.gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;"),
  unicode_slash: base.gsub("/", "\\u002f"),
  null_split: base.gsub("<", "<\0")
}

variants.each { |name, value| puts "#{name}\t#{value}" }