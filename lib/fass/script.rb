class Fass
  class Script
    
    class ScriptError < RuntimeError; end
    
    PASS1_INCLUDE = "lib/fass/pass1.erb"
    PASS2_INCLUDE = "lib/fass/pass2.erb"
    EMBER_OPTIONS = {
      # TODO Add source_file option
      :shorthand => true,
      :infer_end => true,
      :source_line => 1,
    }
    
    attr_accessor :content, :source_file
    
    def initialize(content)
      @content = content
      @source_file = 'SOURCE'
    end
    
    def pass(options={})
      input = content.dup
      ember_options = EMBER_OPTIONS
      if options[:prefix]
        input[0,0] = "%+ #{options[:prefix].inspect}\n"
        ember_options[:source_line] -= 1
      end
      renderer = Ember::Template.new(input, ember_options)
      begin
        renderer.render
      rescue ScriptError => err
        trace = err.backtrace.find{|line| line =~ /SOURCE/}
        if trace =~ /^\s*SOURCE\s*:\s*(\d+)/
          trace = "#{@source_file}, line #{$1}"
        end
        abort "Error: #{err} at #{trace}"
      end
    end
    
    def check_acts
      (1...$acts.size).each do |a|
        if $acts[a]
          (1...$acts[a].size).each do |s|
            warn "Warning: Missing Act #{a}, Scene #{s}" unless $acts[a][s]
          end
        else 
          warn "Warning: Missing Act #{a}"
        end
      end
    end
    
    # TODO Preprocessing pass: make sure % line, etc. are properly defined
    def render
      pass :prefix=>PASS1_INCLUDE
      check_acts
      pass :prefix=>PASS2_INCLUDE
    end
  end
end