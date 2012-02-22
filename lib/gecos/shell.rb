# Simple Shell interface
# I created a separate class for this to encapsulate system dependencies

class GECOS
  class Shell
    attr_accessor :dryrun
    
    def initialize(options={})
      @dryrun = options[:dryrun]
    end
    
    def invoke(command, *args)
      self.send(command, *args)
    end
      
    def _ex(task)
      warn task
      system(task) unless @dryrun
    end
    private :_ex

    def shell_quote(f)
      f.inspect
    end

    def _run(command, *files)
      files = files.map do |f| 
        redir = ''
        if f =~ /^(\d?[><|&?])(.*)$/
          redir = $1
          f = $2
        end
        redir + shell_quote(f)
      end
      cmd = command + ' ' + files.join(' ')
      _ex cmd
    end
    private :_run

    def rm_rf(file)
      _run "rm -rf", file
    end
    
    def mkdir_p(file)
      _run 'mkdir -p', file
    end
    
    def ln_s(from, to)
      _run "ln -s", from, to
    end
    
    def cp(from, to)
      _run "cp", from, to
    end
    
    def thaw(*args)
      _run "gecos freezer thaw", *args
    end
    
    def unpack(*args)
      _run "gecos unpack", *args
    end
    
    def set_timestamp(file, timestamp)
      _run "touch -t", timestamp.strftime('%Y%m%d%H%M.%S'), file
    end
    
    def write(file, content, options={})
      if file.nil? || file == '-'
        STDOUT.write content
      else
        File.open(file, 'w') {|f| f.write content}
        if options[:timestamp]
          shell = Shell.new
          shell.set_timestamp(file, options[:timestamp])
        end
      end
    end
  end
end
