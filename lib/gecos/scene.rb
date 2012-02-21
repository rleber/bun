class Fass
  class Script
    class Scene
      attr_reader :script, :start

      CAST_OF_CHARACTERS = /cast\s+of\s+characters\s*:\s*$/i
      CAST_LIST = /^(\s*([a-z][a-z\.\s-]*?)[\*\.\s]+\((.*?)\))+\s*$/i
      CAST_MEMBER = /([a-z][a-z\.\s-]*?)[\*\.\s]+\((.*?)\)/i
      
      def initialize(script, start)
        @script = script
        @start  = start
      end
      
      def stop
        start + script.size - 1
      end
      
      # Find line numbers of the start of Cast of Characters lists (cached)
      def cast_start
        @cast_start ||= _cast_start
      end
      
      # Find line numbers of the start of Cast of Characters lists (cached)
      def _cast_start
        line_index = 0
        loop do
          line = script[line_index]
          return nil unless line # Past the end; Cast of characters not found
          break if line =~ CAST_OF_CHARACTERS
          line_index += 1
        end
        line_index
      end
      private :_cast_start
      
      def cast_end
        @cast_end ||= _cast_end
      end
      
      def _cast_end
        return nil unless cast_start
        cast_start + cast_list.size - 1
      end
      private :_cast_end
      
      # Retrieve name of scene (cached)
      def name
        @name ||= _name
      end
      
      # Retrieve the name of the scene
      def _name
        return nil unless cast_start
        name_lines = script[0..cast_start] # Including "Cast of Characters" because sometime line breaks get missed
        name_lines[-1].sub!(CAST_OF_CHARACTERS,'') # Remove "Cast of Characters" in last line
        name_lines.join(' ').gsub(/\s+/, ' ')
      end
      private :_name
      
      # Retrieve the lines in the script that list the cast (cached)
      def cast_list
        @cast_list ||= _cast_list
      end
      
      # Retrieve the lines in the script that list the cast
      def _cast_list
        return [] unless cast_start
        cast = []
        line_index = cast_start
        loop do
          line = script[line_index]
          break unless line
          cast << line
          line_index += 1
          break unless script[line_index] && script[line_index] =~ CAST_LIST
        end
        cast
      end
      private :_cast_list
      
      # Retrieve list of the cast (cached)
      def cast
        @cast ||= _cast
      end
      
      # Retrieve list of the cast
      def _cast
        defining_lines = cast_list[1..-1]
        return [] unless defining_lines
        cast_members = []
        defining_lines.each do |defining_line|
          new_cast = defining_line.scan(CAST_MEMBER)
          new_cast.each do |full, nick|
            cast_members << {:nickname=>nick.strip, :full_name=>full.strip}
          end
        end
        cast_members
      end
      private :_cast
      
      def action
        @action ||= _action
      end
      
      def _action
        return script unless cast_start
        script[(cast_end+1)..-1] || []
      end
      private :_action
    end
  end
end