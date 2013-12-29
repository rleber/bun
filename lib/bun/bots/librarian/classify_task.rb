#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

DEFAULT_THRESHOLD = 20
desc "classify FROM [TO]", "Classify files based on whether they're clean or not, etc."
option 'dryrun',    :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually classify"
option "link",      :aliases=>"-l", :type=>"boolean", :desc=>"Symlink files to clean/dirty directories (instead of copy)"
option 'quiet',     :aliases=>'-d', :type=>'boolean', :desc=>"Quiet mode"
option 'test',      :aliases=>'-t', :type=>'string',  
                    :desc=>"What test? See bun help classify for options",
                    :default=>'clean'
long_desc <<-EOT
Classifies all the files in the library, based on whether they pass certain tests.

If TO is specified, files are linked (or copied) into separate directories, depending
on the outcome of the tests. For instance, if the "clean" test is specified (--test clean),
the files are classified into two directories: TO/clean and TO/dirty.

Available tests include:\x5
#{
  String.check_tests.to_a.map do |key,spec| 
    [key.to_s, spec[:description]]
  end.justify_rows.map{|row| row.join(': ')}.join("\x5")
}
EOT
def classify(from, to=nil)
  no_move = options[:dryrun] || !to
  threshold = options[:threshold] || DEFAULT_THRESHOLD
  library = Library.new(from)
  shell = Shell.new(:dryrun=>no_move)
  shell.rm_rf(to) if to && File.exists?(to)
  command = options[:copy] ? :cp : :ln_s

  Dir.glob(File.join(from,'**','*')).each do |old_file|
    next if File.directory?(old_file)
    f = old_file.sub(/^#{Regexp.escape(from)}\//, '')
    status = Bun::File.check(old_file, options[:test])[:description]
    warn "#{f} is #{status}" unless options[:quiet]
    unless no_move
      new_file = File.join(to, status.to_s, f)
      shell.mkdir_p File.dirname(new_file)
      shell.invoke command, old_file, new_file
    end
  end
end