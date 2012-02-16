require 'thor'
require 'ember'
require 'fass/script'

class Fass
  class Bot < Thor
    
    SCRIPTS_DIRECTORY = 'scripts'
    
    desc "describe", "Describe the scripting language"
    def describe
      puts <<-END
The script engine provides a simple text description language for entering and displaying scripts for
plays. The syntax for this language is based on ERB and Ember. See http://snk.tuxfamily.org/lib/ember
for additional details on the syntax.
  
The specific directives which this tool understands include:
character
characters
scene
direction
song
rev
      END
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
  end
end