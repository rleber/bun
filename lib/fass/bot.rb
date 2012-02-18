require 'thor'
require 'ember'
require 'fass/script'

class Fass
  class Bot < Thor
    
    SCRIPTS_DIRECTORY = 'scripts'
    
    desc "describe", "Describe the scripting language"
    def describe
      puts File.read("doc/script_format_extended.text")
    end
    
    # TODO Add "as performed/as written" flag
    # TODO Add "with notes" flag
    desc 'render FILE', "Render a script file"
    def render(file)
      file = "#{SCRIPTS_DIRECTORY}/#{file}" unless file =~ %r{^/}
      file += '.script' unless file =~ /\.\w*$/
      abort "Script file #{file} does not exist" unless File.exists?(file)
      script = Script.new(File.read(file))
      script.source_file = file
      puts script.render
    end
    
    no_tasks do
      def print_chunks(chunks, level=0)
        return if level > 1
        chunks.each do |chunk|
          if chunk.is_a?(Array)
            print_chunks(chunk, level+1)
          else
            i = chunk.inspect
            prefix = '  '*level
            if i.size>100
              puts "#{prefix}#{i[0...50]}..#{i[-50..-1]}"
            else 
              puts "#{prefix}#{i}"
            end
          end
        end
      end
    end

    desc "rtf FILE", "Read a script from an RTF format file"
    def rtf(file)
      system "rtf2text extract #{file.inspect}"
    end
    
    
    SCENE_END = /-\s*\bf\s*i\s*n\b\s*-/
    CAST_OF_CHARACTERS = /cast\s+of\s+characters\s*:\s*$/i
    CAST_LIST = /^(\s*([a-z][a-z\.\s-]*?)[\*\.\s]+\((.*?)\))+\s*$/i
    CAST_MEMBER = /([a-z][a-z\.\s-]*?)[\*\.\s]+\((.*?)\)/i
    
    desc "clean1 FILE", "Clean an extracted text file (first pass)"
    def clean1(file)
      content = File.read(file)
      content = content.split("\n")
      title = content.find{|line| line =~ /Page\s+1/}
      if title
        title = title[/^.*?\t(.*?)\t/,1].strip if title =~ /\t.*\t/
        title = title.gsub(/\s+/,' ')
        puts "#Title: #{title}"
        puts
      end
      new_content = []
      content.each do |line|
        line = line.gsub("\t",' ').gsub(/ {2,}/,' ').strip
        next unless line.size > 0
        next if line =~ /Page\s+\d+$/
        next if line =~ /\d+\s+\d+\/\d+\/\s+\d+\s+-\d+:\d+$/
        next if line =~ /Page\s+\d+.*F\.A\.S\.S/
        new_content << line
      end
      # Find ends of previous scenes
      scene_ends = [0]
      new_content.each_with_index do |line, i|
        if line =~ SCENE_END
          scene_ends << i+1
        end
      end
      scene_ends.pop # don't need the last one
      # Find "cast of characters"
      cast_starts = []
      new_content.each_with_index do |line, i|
        if line =~ CAST_OF_CHARACTERS
          cast_starts << i
        end
      end
      if scene_ends.size == cast_starts.size
        old_content = new_content
        new_content = []
        cast_starts << old_content.size  # Add a sentinel to the end
        scene_ends.each_with_index do |scene_end, scene_index|
          scene_name = []
          line_index = scene_end
          if line_index == 0
            # There may be garbage at the beginning of the file; ignore it
            while old_content[line_index] !~ /[A-Za-z]/
              line_index += 1
            end
            line_index += 1 # And ignore the name of the play
          end
          while line_index < cast_starts[scene_index]
            scene_name << old_content[line_index]
            line_index += 1
          end
          # Because sometime line breaks get missed:
          scene_name << old_content[line_index].sub(CAST_OF_CHARACTERS,'') if line_index == cast_starts[scene_index]
          scene_name = scene_name.join(' ').gsub(/\s+/, ' ')
          new_content << "Scene ? - ? : #{scene_name}\n"
          new_content << "#CAST FOR SCENE:"
          line_index += 1
          cast = []
          while line_index < cast_starts[scene_index+1] && (old_content[line_index] =~ CAST_LIST || old_content =~ /^\s*$/)
            new_cast = old_content[line_index].scan(CAST_MEMBER)
            new_cast.each do |full, nick|
              cast << [nick.strip, full.strip]
            end
            line_index += 1
          end
          if cast.size > 0
            nickname_width = cast.map{|nick, full| nick.size}.max
            cast.each do |nick, full|
              new_content << %Q{#  #{"%#{-(nickname_width+1)}s"%(nick+':')}  #{full}}
            end
          end
          new_content << ""
          while line_index < cast_starts[scene_index+1]
            break if old_content[line_index] =~ SCENE_END
            new_content << old_content[line_index]
            line_index += 1
          end
        end
      else
        warn "Scene endings (\"fin\") don't match up with casts of characters; unable to isolate scenes"
        warn "  (There are #{scene_ends.size} scene endings, and #{cast_starts.size} casts of characters.)"
        warn "  Scene endings: #{scene_ends.inspect}"
        warn "  Casts of characters: #{cast_starts.inspect}"
      end
      puts new_content.join("\n")
      warn "Please mark the end of each song with \"END OF SONG\" line."
    end
    
    START_OF_SONG = /^SONG:/
    END_OF_SONG = /\bEND\s+OF\s+SONG\b/
    desc "clean2 FILE", "Clean an extracted text file (Second pass)"
    def clean2(file)
      content = File.read(file).split("\n")
      
      # First, find and mark songs
      in_song = false
      new_content = []
      content.each do |line|
        if line=~/\*{5}/ .. line=~END_OF_SONG
          new_content << "SONG:" unless in_song
          if line =~ END_OF_SONG
            new_content << line
            in_song = false
          else
            new_content << "    #{line}"
            in_song = true
          end
        else
          if in_song
            new_content << "END OF SONG"
          end
          in_song = false
          new_content << line
        end
      end
     
      # Now, fix line endings and merge lines
      # TODO Better handling of hypenated words?
      old_content = new_content
      new_content = []
      preserve_breaks = false
      last_line = ""
      old_content.each do |line|
        new_content << "" if preserve_breaks ||
                             last_line =~ END_OF_SONG || 
                             new_content.size == 0 ||
                             line =~ /^.[LS]-\d+(?:\]|$|.\s*\()/ ||
                             line =~ /^\([A-Z]/ ||
                             line =~ /^[A-Z][A-Z, \.-]+:\s/ ||
                             line =~ /^Scene\s+\?\s+-\s+\?/ ||
                             line =~ START_OF_SONG ||
                             line =~ /^#/
        case line
        when START_OF_SONG
          preserve_breaks = true
        when END_OF_SONG
          preserve_breaks = false
        end
        new_content[-1] += ' ' unless new_content[-1] =~ /^$|\s$/
        new_content[-1] += line
        last_line = line
      end
      
      # Now, insert extra empty lines
      old_content = new_content
      new_content = []
      extra_space = true
      in_cast = false
      in_song = false
      
      old_content.each do |line|
        if line =~ /^#/
          extra_space = false if in_cast
        else
          in_cast = false
          extra_space = true unless in_song
        end
        new_content << "" if extra_space && new_content.size > 0
        new_content << line
        case line
        when /^#CAST FOR SCENE/
          in_cast = true
        when START_OF_SONG
          extra_space = false
          in_song = true
        when END_OF_SONG
          extra_space = true
          in_song = false
        end
      end
      
      # Finally, fix songs
      old_content = new_content
      new_content = []
      i = 0
      while i<old_content.size
        line = old_content[i]
        case line
        when START_OF_SONG
          # Find lines with stars in them
          j = i+1
          while j<old_content.size && old_content[j] !~ END_OF_SONG
            j += 1
          end
          # At this point lines i...j are the song; back up and look for the last "*****"
          while j>i && old_content[j] !~ /\*{5}/
            j -= 1
          end
          # Now lines (i+1)...j are the song information block
          song_information = old_content[(i+1)...j].join
          song_name = song_information[/^[\s\*]*([^\*]+)/,1].strip
          tune = song_information[/([^\*]+)[\s\*]*$/,1].strip
          new_content += ["    SONG: #{song_name}", "    (To the tune of: #{tune})"]
          i = j+1
        when END_OF_SONG
          i += 1  # Discard end of song markers; we don't need them anymore
        else
          new_content << line
          i += 1
        end
      end
      
      # Output the results
      puts new_content.join("\n")
    end
  end
end