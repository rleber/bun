#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

CHECK_TESTS = {
  clean: {
    options: [:clean, :dirty],
    description: "File contains special characters",
    test: lambda {|text| File.clean?(text) ? :clean : :dirty }
  }
}
# TODO -- As is, this is kind of useless. It just checks the raw ASCII of a file
desc "check FILE", "Test a file for cleanness, etc."
option 'test',  :aliases=>'-t', :type=>'string',  :desc=>"What test? See bun check for options",
                :default=>'clean'
option 'quiet', :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
long_desc <<-EOT
Checks the file to see whether it passes certain tests.

Available tests include:\x5
#{
  CHECK_TESTS.to_a.map do |key,spec| 
    [key.to_s, spec[:description]]
  end.justify_rows.map{|row| row.join(': ')}.join("\x5")
}
EOT
def check(file)
  test = options[:test].to_sym
  spec = CHECK_TESTS[test]
  unless spec
    warn "!Invalid test: #{options[:test]}" unless options[:quiet]
    exit(99)
  end
  content = ::Bun.readfile(file, :encoding=>'ascii-8bit')
  test_result = spec[:test].call(content)
  ix = spec[:options].index(test_result)
  ix ||= spec[:options].size
  puts test_result.to_s unless options[:quiet]
  exit(ix)
end
