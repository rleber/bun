#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

DOUBLE_QUOTE_REGEXP = /"(?:[^"\\]|\\.)*"/
SINGLE_QUOTE_REGEXP = /'(?:[^'\\]|\\.)*'/
NON_QUOTED_REGEXP = /[^'"\s][^,:]*\S|[^'"\s]/
PHRASE_REGEXP = /(?:#{DOUBLE_QUOTE_REGEXP}|#{SINGLE_QUOTE_REGEXP}|#{NON_QUOTED_REGEXP})/
TAG_VALUE_PAIR_REGEXP = /(#{PHRASE_REGEXP})
                         \s*:\s*
                         (#{PHRASE_REGEXP})/x
TAG_REGEXP = /^\s*
              (?:#{TAG_VALUE_PAIR_REGEXP})
              (?:\s*,\s*
                (?:#{TAG_VALUE_PAIR_REGEXP})
              )*
              \s*$/x

desc "mark FILE [TO]", "Mark an unpacked or decoded Bun file with arbitrary tag information"
option "tag", :aliases=>'-t', :type=>'string',  :desc=>"tag:value,..."
def mark(file, to=nil)
  check_for_unknown_options(file, to)
  stop "!Bad --tag. Use --tag tag:value,..." unless tag_match = TAG_REGEXP.match(options[:tag])
  tag_pairs = tag_match[1..-1].compact.each_slice(2)
  tag_pairs = tag_pairs.map do |tag, value|
    tag = eval(tag) if tag =~ /^['"]/ # Remove quoting
    value = eval(value) if value =~ /^['"]/ # Remove quoting
    [tag, value]
  end
  File::Unpacked.mark(file, tag_pairs, to)
end