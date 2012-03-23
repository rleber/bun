#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Run this; check if there's a way to discern listing files automagically
desc "text_status", "Show status of text files"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'build',   :aliases=>'-b', :type=>'boolean', :desc=>'Rebuild the text statistics, even if they\'re already set'
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
long_desc <<-END
Displays the "status" of text files: e.g. could they be successfully unpacked? Did they contain tabs? Did they contain invalid characters?
Classifies whether the file could be successfully decoded. (If not, it's generally because of bad block headers.)
Counts all characters, and the following special characters: tabs, backspaces, form-feeds, vertical tabs, other non-printable characters. 
Produces a list of all other non-printable characters encountered.
END
def text_status
  archive = Archive.new(:location=>options[:archive])
  directory = archive.location
  table = []
  archive.each do |tape_name|
    $stderr.puts tape_name unless options[:quiet]
    descr = archive.descriptor(tape_name)
    # TODO Apply this to frozen files, too
    next unless descr.file_type == :text
    if options[:build] || descr.bad_characters.nil?
      text = archive.open(tape_name) {|f| f.text rescue nil }
      descr = archive.descriptor(tape_name)
    end
    if descr.good_blocks > 0
      tabs = descr.bad_characters["\t"] || 0
      backspaces = descr.bad_characters["\b"] || 0
      form_feeds = descr.bad_characters["\f"] || 0
      vertical_tabs = descr.bad_characters["\v"] || 0
      bad_character_set = (descr.bad_characters.keys - ["\t","\b","\f","\v"]).sort.join
      bad_characters = descr.bad_characters.reject{|ch,ct| ["\t","\b","\f","\v"].include?(ch) }.map{|ch,ct| ct}.inject{|sum,ct| sum+ct } || 0
      status = descr.good_blocks < descr.blocks ? "Truncated" : "Readable"
      table << [tape_name, status, descr.blocks, descr.good_blocks, descr.character_count, tabs, backspaces, vertical_tabs, form_feeds, bad_characters, bad_character_set.inspect[1...-1]]
    else
      table << [tape_name, 'Unreadable', descr.blocks, 0]
    end
  end
  if table.size == 0
    puts "No files unpacked"
  else
    table.unshift %w{Tape Status Blocks Good\ Blocks Chars Tabs Backspaces Vertical\ Tabs Form\ Feeds Invalid\ Characters List}
    puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  end
end