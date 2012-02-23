# Simple Shell interface
# I created a separate class for this to encapsulate system dependencies

class GECOS
  class Shell
    attr_accessor :dryrun, :quiet
    
    def initialize(options={})
      @dryrun = options[:dryrun]
      @quiet = options[:quiet]
    end
    
    def invoke(command, *args)
      self.send(command, *args)
    end
      
    def _ex(task, options={})
      quiet = options.has_key?(:quiet) ? options[:quiet] : @quiet
      dryrun = options.has_key?(:dryrun) ? options[:dryrun] : @dryrun
      warn task unless quiet
      res = true
      res = system(task) unless dryrun
      abort "Command #{task} failed" unless res || options[:allow]
      res
    end
    private :_ex

    def shell_quote(f)
      f.inspect
    end

    def _run(command, *args)
      options = {}
      options = args.pop if args.last.is_a?(Hash)
      files = args.map do |f| 
        redir = ''
        if f=~/^-.*/
          f             # Do not do shell quoting on --options
        else            # Do shell quoting
          if f =~ /^(\d?[><|&?])(.*)$/ # Watch out for redirection
          redir = $1
          f = $2
          end
          redir + shell_quote(f)
        end
      end
      cmd = command + ' ' + files.join(' ')
      _ex cmd, options
    end
    private :_run

    def rm_rf(file, options={})
      _run "rm -rf", file, options
    end
    
    def mkdir_p(file, options={})
      _run 'mkdir -p', file, options
    end
    
    def ln_s(from, to, options={})
      _run "ln -s", from, to, options
    end
    
    def cp(from, to, options={})
      _run "cp", from, to, options
    end
    
    def thaw(*args)
      if args.last.is_a?(Hash)
        if args.last[:log]
          args.unshift "--log #{shell_quote(args.last[:log])}"
        end
      end
      _run "gecos freezer thaw", *args
    end
    
    def unpack(*args)
      if args.last.is_a?(Hash)
        if args.last[:log]
          args.unshift "--log #{shell_quote(args.last[:log])}"
        end
      end
      _run "gecos unpack", *args
    end
    
    def set_timestamp(file, timestamp, options={})
      _run "touch -t", timestamp.strftime('%Y%m%d%H%M.%S'), file, options
    end
    
    def write(file, content, options={})
      if file.nil? || file == '-'
        STDOUT.write content
      else
        File.open(file, 'w') {|f| f.write content}
        set_timestamp(file, options[:timestamp], options) if options[:timestamp]
      end
    end
    
    def log(file, message)
      File.open(file, 'a') {|f| f.puts Time.now.strftime('%Y/%m/%d %H:%M:%s') + ' ' + message.to_s }
    end
  end
end
