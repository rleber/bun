#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Run this; check if there's a way to discern listing files automagically
desc "text_status ARCHIVE", "Show status of text files"
option 'build',   :aliases=>'-b', :type=>'boolean', :desc=>'Rebuild the text statistics, even if they\'re already set'
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
long_desc <<-END
Displays the "status" of text files: e.g. could they be successfully unpacked? Did they contain tabs? Did they contain invalid characters?
Classifies whether the file could be successfully decoded. (If not, it's generally because of bad block headers.)
Counts all characters, and the following special characters: tabs, backspaces, form-feeds, vertical tabs, other non-printable characters. 
Produces a list of all other non-printable characters encountered.
END
def text_status(at)
  archive = Archive.new(at)
  directory = archive.at
  table = []
  archive.each do |hoard|
    $stderr.puts hoard unless options[:quiet]
    descr = archive.descriptor(hoard)
    # TODO Apply this to frozen files, too
    case descr.file_type
    when :text
      if options[:build] || descr.control_characters.nil?
        text = archive.open(hoard) {|f| f.text rescue nil }
        descr = archive.descriptor(hoard)
      end
      if descr.good_blocks > 0
        tabs = descr.control_characters["\t"] || 0
        backspaces = descr.control_characters["\b"] || 0
        form_feeds = descr.control_characters["\f"] || 0
        vertical_tabs = descr.control_characters["\v"] || 0
        bad_character_set = (descr.control_characters.keys - ["\t","\b","\f","\v"]).sort.join
        control_characters = descr.control_characters.reject{|ch,ct| ["\t","\b","\f","\v"].include?(ch) }.map{|ch,ct| ct}.inject{|sum,ct| sum+ct } || 0
        status = descr.status.capitalize
        table << [hoard, status, descr.blocks, descr.good_blocks, descr.character_count, tabs, backspaces, vertical_tabs, form_feeds, control_characters, bad_character_set.inspect[1...-1]]
      else
        table << [hoard, 'Unreadable', descr.blocks, 0]
      end
    when :frozen
      archive.open(hoard) do |frozen_file|
        frozen_file.shard_count.times do |i|
          $stderr.puts "#{hoard}[#{i}]" unless options[:quiet]
          descr = frozen_file.shard_descriptor(i)
          if options[:build] || descr.control_characters.nil?
            text = frozen_file.shards.at(i)
            descr = frozen_file.shard_descriptor(i)
          end
          tabs = descr.control_characters["\t"] || 0
          backspaces = descr.control_characters["\b"] || 0
          form_feeds = descr.control_characters["\f"] || 0
          vertical_tabs = descr.control_characters["\v"] || 0
          bad_character_set = (descr.control_characters.keys - ["\t","\b","\f","\v"]).sort.join
          control_characters = descr.control_characters.reject{|ch,ct| ["\t","\b","\f","\v"].include?(ch) }.map{|ch,ct| ct}.inject{|sum,ct| sum+ct } || 0
          status = descr.status.to_s.capitalize
          table << ["#{hoard}[#{i}]", status, nil, nil, descr.character_count, tabs, backspaces, vertical_tabs, form_feeds, control_characters, bad_character_set.inspect[1...-1]]
        end
      end
    end
  end
  if table.size == 0
    puts "No files unpacked"
  else
    table.unshift %w{Hoard Status Blocks Good\ Blocks Chars Tabs Backspaces Vertical\ Tabs Form\ Feeds Invalid\ Characters List}
    puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  end
end