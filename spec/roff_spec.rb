#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def roff(title, text, options={})
  prefix = "roff test"
  context title do
    before :all do
      if options[:keep]
        path = File.join(ENV['HOME'],'.roff_test')
        exec("rm -rf path")
        ::File.open(path, 'w') {|f| f.write text}
        @command = "roff #{path}"
      else
        tempfile_prefix = "roff_test_#{title.gsub(/\s+/,'_').gsub(/_+/,'_').gsub(/[^a-zA-Z0-9_]/,'')}_"
        t = Tempfile.new("roff_test_#{title.gsub(/\s+/,'_').gsub(/_+/,'_').gsub(/[^a-zA-Z0-9_]/,'')}_")
        t.write(text)
        t.close
        command = "roff #{t.path}"
      end
      @output_basename = (prefix + "_" + title).gsub(/\W/,'_').gsub(/_+/,'_')
      @actual_output_file = File.join('output', 'test_actual', @output_basename)
      @expected_output_file = File.join('output', 'test_expected', @output_basename)
      @allowed_codes = options[:allowed] || [0]
      @allowed_codes << 1 if options[:fail]
      exec("rm -rf #{@actual_output_file}")
      exec_command = "bun #{command} >#{@actual_output_file}"
      exec_command += " 2>&1" unless options[:trap_stderr]==false
      exec(exec_command, allowed: @allowed_codes)
    end
    if options[:fail]
      it "should fail" do
        $?.exitstatus.should == 1
      end
    end
    it "should generate the expected output" do
      @output_basename.should match_expected_output
    end
    after :all do 
      backtrace
      exec_on_success("rm -rf #{@actual_output_file}")
    end
  end
end

def roff_std(title, commands, options={})
  commands = commands.join("\n") if commands.is_a?(Array)
  commands = ".debug\n" + commands if options[:debug]
  text = <<-EOT
.m1 1
.m2 2
.m3 2
.m4 1
.eh 'Even'Head'%'
.ef 'Even'Foot'%'
.oh 'Odd'Head'%'
.of 'Odd'Foot'%'
.ll 25
.li
1234567890123456789012345
.ll 20
.ll 20
#{commands}
Now is the time for everyone, including all 
good men, to go down to the sea 
in ships again.
EOT
  roff(title, text, options)
end

describe Bun::Roff do
  roff_std "base", ""
  roff_std "no justify", ".nj"
  roff_std "justify", [".nj","This is some unjustified text, which should be followed by some justified text.",".ju"]
  roff_std "no fill", ".nf"
  roff_std "break", ["A break should occur immediately after this text.", ".br"]
  roff_std "page break", ["A page break should occur immediately after this text", ".bp"]
  roff_std "odd page (from odd)", ["A page break and a blank page should follow this one", ".op"]
  roff_std "odd page (from even)", ["A page break should follow this", ".bp", "And another should follow this", ".op"]
  roff_std "even page (from odd)", ["A page break should follow this", ".ep"]
  roff_std "even page (from even)", ["A page break should follow this", ".bp", "And a page break and a blank page should follow this", ".ep"]
  roff_std "pa", ["This should be followed by a page break, then page 10", ".pa 10"]
  roff_std "sl 0 (no impact)", ["Page break, no form feed character", ".sl 0", ".bp"]
  roff_std "sl 1 (no impact)", ["Page break, no form feed character (because .sl is not implemented)", ".sl 1", ".bp"]
  roff_std "line break on leading space", ["A line break should appear next"," << before this"]
  roff_std "double space after sentence", [".nj", "There should be two spaces after this next word."]
  roff_std "double space after question", [".nj", "There should be two spaces after this next word?"]
  roff_std "double space after exclamation", [".nj", "There should be two spaces after this next word!"]
  roff_std "double space after colon", [".nj", "There should be two spaces after this next word:"]
  roff_std "single space after semicolon", [".nj", "There should be one space after this next word;"]
  roff_std "no double space after period in middle of line", [".nj", "There should be one space after this next word. See?"]
  roff_std ".sp 2", ["Two blank lines should follow this", ".sp 2"]
  roff_std ".sp", ["One blank line should follow this", ".sp"]
  roff_std ".sp does not create blank lines at the top of the page", [".pl 10", "Only one blank line after this", ".sp 5"]
  roff_std ".cc", ["The next line should begin no_fill",".cc $", "$nf", ".nj"]
  roff_std ".lv creates blank space on the page", ["Three blank lines after this", ".lv 3"]
  roff_std ".lv creates blank space on the next page", [".pl 10", "Only one blank line after this", ".lv 3"]
  roff_std ".ls 2", ".ls 2"
  roff_std ".ls plus 1", ".ls +1"
  roff_std ".ls minus 1", [".ls +1", "Here's some stuff that should be double-spaced.",".ls -1", "And single."]
  roff_std ".li", ["This stuff should be justified, hyphenated, etc.",".li",".sp should be ignored and the rest taken literally","And we're back to being justified, as usual"]
  roff_std ".li 2", ["This stuff should be justified, hyphenated, etc.",".li 2",".sp should be ignored and the rest taken literally",".fi should also be ignored", "And we're back to being justified, as usual"]
  roff_std ".an foo", [".an foo","Foo (expecting 0): ^(foo)"]
end