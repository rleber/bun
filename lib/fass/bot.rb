require 'thor'
require 'ember'
require 'fass/script'

class Fass
  class Bot < Thor
    
    SCRIPTS_DIRECTORY = 'scripts'
    
    desc 'render FILE', "Render a script file"
    def render(file)
      file = "#{SCRIPTS_DIRECTORY}/#{file}" unless file =~ %r{^/}
      file += '.script' unless file =~ /\.\w*$/
      abort "Script file #{file} does not exist" unless File.exists?(file)
      script = Script.new(File.read(file))
      puts script.render
    end
  end
end