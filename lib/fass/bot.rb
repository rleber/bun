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

    EXCERPT_SIZE = 100
    desc "rtf FILE", "Read a script from an RTF format file"
    def rtf(file)
      system "rtf2text extract #{file.inspect}"
    end
  end
end