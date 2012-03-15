require 'lib/bun/scene'

class Bun
  class Script
    class Cleaner
      SCENE_END = /-\s*\bf\s*i\s*n\b\s*-/
      CAST_OF_CHARACTERS = /cast\s+of\s+characters\s*:\s*$/i
      CAST_LIST = /^(\s*([a-z][a-z\.\s-]*?)[\*\.\s]+\((.*?)\))+\s*$/i
      CAST_MEMBER = /([a-z][a-z\.\s-]*?)[\*\.\s]+\((.*?)\)/i
      START_OF_SONG = /^SONG:/
      END_OF_SONG = /\bEND\s+OF\s+SONG\b/
      
      attr_accessor :text
      
      def initialize(text)
        @text = text
      end

      # First pass cleaning
      # TODO better elimination of page headings
      # TODO prompt for song endings; combine with clean2
      # TODO remember/mark song endings for future runs
      # TODO allow song endings to be provided as a hash {"SONG_NAME" => <line on which song ends>, ... }
      # TODO make clean1 repeatable with destructive results
      
      def clean1
        content = text.split("\n")
        title = get_title(content)
        content = clean_lines(content)                    # Clean up tabs, and garbage lines
        content = clean_scenes(content)                   # Clean up scene casts of characters
        content[0,0] = ["#Title: #{title}", ""] if title  # Insert the title, if any
        text = content.join("\n")                         # Save the results
      end
      
      def get_title(script)
        script = script.split("\n") if script.is_a?(String)
        title_line = script.find{|line| line =~ /Page\s+1/}
        title = nil
        if title_line
          title = title_line[/^.*?\t(.*?)\t/,1].strip if title_line =~ /\t.*\t/
          title = title.gsub(/\s+/,' ')
        end
        title
      end
      
      # Clean up lines a script:
      # - Remove tabs and excess whitespace
      # - Remove blank lines and page headers and footers
      def clean_lines(script)
        script = script.split("\n") if script.is_a?(String)
        new_content = []
        script.each do |line|
          line = line.gsub("\t",' ').gsub(/ {2,}/,' ').strip
          next unless line.size > 0
          next if line =~ /Page\s+\d+$/
          next if line =~ /\d+\s+\d+\/\d+\/\s+\d+\s+-\d+:\d+$/
          next if line =~ /Page\s+\d+.*F\.A\.S\.S/
          new_content << line
        end
        new_content
      end
      
      # Clean up Scenes: Casts of Characters and scene names
      def clean_scenes(script)
        script = script.split("\n") if script.is_a?(String)
        scenes = get_scenes(script)
        content = []
        scenes.each do |scene|
          content += clean_scene(scene)
        end
        content
      end
      
      # Separate the scenes in the script
      def get_scenes(script)
        script = script.split("\n") if script.is_a?(String)
        scene_starts = find_scene_starts(script)
        scene_ends = find_scene_ends(script)
        scene_starts.zip(scene_ends).map {|s, e| Bun::Script::Scene.new(script[s..e], s) }
      end
      
      def clean_scene(scene)
        content = []
        content << "Scene ? - ? : #{scene.name}" if scene.name
        cast = cleaned_cast(scene)
        if cast.size > 0
          content << "" if content.size > 0
          content += cast
        else
          warn "Unable to find Scene Cast of Characters for scene starting on line #{scene.start}"
        end
        content << ""
        action = scene.action
        action.pop if action[-1] =~ SCENE_END # Don't include the final '- fin -'
        content += scene.action
        content
      end
      
      # Find line numbers of the starts of scenes
      #   Based on finding the ends of the scenes
      def find_scene_starts(script)
        script = script.split("\n") if script.is_a?(String)
        scene_ends = find_scene_ends(script)
        scene_starts = scene_ends.map{|e| e+1} # Point to the next line after the "- fin -" marker
        scene_starts.unshift(start_of_first_scene(script))  # Add a scene start to the beginning
        scene_starts.pop # don't need the last one
        scene_starts
      end
      
      # Find the line number of the start of the first scene, ignoring garbage
      # that often exists at the start of the file, and the line with the title of the play
      def start_of_first_scene(script)
        script = script.split("\n") if script.is_a?(String)
        line_index = 0
        loop do
          line = script[line_index]
          break unless line
          break if line =~ /[A-Za-z]/
          line_index += 1
        end
        line_index += 1 if line_index < script.size # And ignore the name of the play
        line_index
      end
      
      # Find line numbers of the ends of scenes
      #   Uses the '- fin -' markers to find them
      def find_scene_ends(script)
        script = script.split("\n") if script.is_a?(String)
        scene_ends = []
        script.each_with_index do |line, i|
          if line =~ SCENE_END
            scene_ends << i
          end
        end
        scene_ends
      end
      
      # Cleaned up cast listing for a scene
      def cleaned_cast(scene)
        cast = scene.cast
        return [] if cast.size == 0
        content = []
        content << "#CAST FOR SCENE:"
        # TODO Refactor using Array#justify_rows
        nickname_width = cast.map{|member| member[:nickname].size}.max
        cast.each do |member|
          content << %Q{#  #{"%#{-(nickname_width+1)}s"%(member[:nickname]+':')}  #{member[:full_name]}}
        end
        content
      end

      # Second pass cleaning
      # TODO Better isolation of song names and "to the tune of"s
      # TODO Better handling of hypenated words when combining lines?
      # TODO Don't double up line spacing if blank lines already exist
      # TODO make clean2 repeatable with destructive results
      
      def clean2
        content = text.split("\n")
  
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
  
        # Save the results
        text = new_content.join("\n")
      end
    end
  end
end
