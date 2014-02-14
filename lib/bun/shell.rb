#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Simple Shell interface
# I created a separate class for this to encapsulate system dependencies

require 'shellwords'

module Bun
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
      dryrun = options.has_key?(:dryrun) ? options[:dryrun] : @dryrun
      quiet = options.has_key?(:quiet) ? options[:quiet] : @quiet
      quiet = quiet.nil? ? !dryrun : (quiet && !dryrun)
      warn task unless quiet
      res = true
      res = system(task) unless dryrun
      stop "!Command #{task} failed" unless res || options[:allow]
      res
    end
    private :_ex

    def shell_quote(f)
      Shellwords.escape(f)
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
    
    def cp_r(from, to, options={})
      _run "cp -r", from, to, options
    end
    
    def mv(from, to, options={})
      _run "mv", from, to, options
    end

    # "Forced" move: delete existing file, if any, first
    # This prevents mv a=>b from creating b/a if b exists and is a directory
    # IT WILL CLOBBER FILES
    def mv_f(from, to, options={})
      temp = File.temporary_file_name('mv_f_')
      mv from, temp, options
      rm_rf to, options
      mv temp, to, options
    end
    
    # Move with creating any necessary directories first
    def mv_p(from, to, options={})
      mkdir_p File.dirname(to), options
      mv_f from, to, options
    end

    # Move file, avoiding possible conflicts by moving conflicting files using "versioning"
    # Block is invoked before every move; this allows messaging etc. Block must return non-nil,
    # or moves are suspended
    def merge_files(files, to, &blk)
      File.moves_to_merge(files, to).each do |move|
        continue = true
        continue = yield(move) if block_given?
        break unless continue
        mv_p move[:from], move[:to]
      end
    end
    
    # TODO Is this used?
    def decode(*args)
      options = {}
      options = args.pop if args.last.is_a?(Hash)
      args.push "--at #{options[:at].inspect}" if options[:at]
      _run "bun freezer decode", *args
    end
    
    # TODO Is this used?
    def unpack(*args)
      options = {}
      options = args.pop if args.last.is_a?(Hash)
      args.push "--at #{options[:at].inspect}" if options[:at]
      _run "bun unpack", *args
    end
    
    def set_timestamp(file, timestamp, options={})
      _run "touch -t", timestamp.strftime('%Y%m%d%H%M.%S'), file, options
    end
    
    def write(file, content, options={})
      case file
      when nil
        # Do nothing
      when '-'
        $stdout.write content
      when IO
        file.write content
      else
        mode = options[:mode] || 'w'
        begin
          ::File.open(file, mode) {|f| f.write content }
        rescue => e 
          debug "pwd: #{Dir.pwd}"
          debug "file: #{file.inspect}"
          debug "mode: #{mode.inspect}"
          raise
        end
        set_timestamp(file, options[:timestamp], options) if options[:timestamp]
      end
      content
    end

    def append(file, content, options={})
      write(file, content, options.merge(mode: 'a'))
    end

    def puts(file, content, options={})
      append(file, content+"\n", options)
    end
    
    def log(file, message)
      file = $stderr if file == '-'
      puts file, "#{Time.now.strftime('%Y/%m/%d %H:%M:%S')} #{message}"
    end
  end
end