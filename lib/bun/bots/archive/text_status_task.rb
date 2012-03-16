# TODO Run this; check if there's a way to discern listing files automagically
desc "text_status", "Show status of text files"
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
long_desc <<-END
Displays the "status" of text files: e.g. could they be successfully unpacked? Did they contain tabs? Did they contain invalid characters?
Classifies whether the file could be successfully decoded. (If not, it's generally because of bad block headers.)
Counts all characters, and the following special characters: tabs, backspaces, form-feeds, vertical tabs, other non-printable characters. 
Produces a list of all other non-printable characters encountered.
END
def text_status
  directory = options[:archive] || Archive.location
  archive = Archive.new(directory)
  table = []
  archive.each do |tape_name|
    file = archive.open(tape_name)
    next unless file.file_type == :text
    text = file.text rescue nil
    truncated = !text
    if truncated
      file.truncate = true
      file.reblock
      text = file.text rescue nil
    end
    if text && file.good_blocks > 0
      tabs = backspaces = form_feeds = vertical_tabs = bad_characters = 0
      bad_character_set = []
      text.scan("\t") { tabs += 1 }
      text.scan("\b") { backspaces += 1 }
      text.scan("\f") { form_feeds += 1 }
      text.scan("\v") { vertical_tabs += 1 }
      text.scan(File.invalid_character_regexp) {|m| bad_characters += 1; bad_character_set << m.to_s }
      status = truncated ? "Truncated" : "Readable"
      table << [tape_name, status, file.blocks, file.good_blocks, text.size, tabs, backspaces, vertical_tabs, form_feeds, bad_characters, bad_character_set.uniq.sort.join.inspect[1...-1]]
    else
      table << [tape_name, 'Unreadable', file.blocks, 0]
    end
  end
  if table.size == 0
    puts "No files unpacked"
  else
    table.unshift %w{Tape Status Blocks Good\ Blocks Chars Tabs Backspaces Vertical\ Tabs Form\ Feeds Invalid\ Characters List}
    puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  end
end
