class Fass
  class Script
    
    SCRIPT_INCLUDE = "lib/fass/script.erb"
    EMBER_OPTIONS = {
      # TODO Add source_file option
      :shorthand => true,
      :infer_end => true,
    }
    
    attr_accessor :content
    
    def initialize(content)
      @content = content
    end
    
    def render
      input = content
      input[0,0] = "%+ #{SCRIPT_INCLUDE.inspect}\n" unless input =~ /^\s*%\+/
      renderer = Ember::Template.new(input, EMBER_OPTIONS)
      context = ::Kernel.binding
      begin
        renderer.render(context)
      rescue => err
        puts renderer.program
        trace = err.backtrace.join("\n")
        abort "Script processing terminated with error:\n#{err}\n#{trace}"
      end
    end
  end
end