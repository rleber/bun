#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def roff(title, text, options={})
  prefix = "roff test"
  context title do
    before :all do
      path = File.join(ENV['HOME'],'.roff_test')
      exec("rm -rf path")
      ::File.open(path, 'w') {|f| f.write text}
      command = "roff #{path}"
      @output_basename = (prefix + "_" + title).gsub(/\W/,'_').gsub(/_+/,'_')
      @actual_output_file = File.join('output', 'test_actual', @output_basename)
      @expected_output_file = File.join('output', 'test_expected', @output_basename)
      @allowed_codes = options[:allowed] || [0]
      @allowed_codes << 1 if options[:fail]
      exec("rm -rf #{@actual_output_file}")
      option_string = $debug ? '--debug ' : ''
      exec_command = "bun #{command} #{option_string}>#{@actual_output_file}"
      exec_command += " 2>&1" unless $debug || options[:trap_stderr]==false
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
#{commands}
Now is the time for everyone, including all 
good men, to go down to the sea 
in ships again.
EOT
  warn text if options[:debug]
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
  roff_std ".an foo", [".an foo",".ic ^^", "Foo (expecting 0): ^(foo)"]
  roff_std ".an foo with no ic", [".an foo", "Foo (expecting no substitution): ^(foo)"]
  roff_std ".an foo n", [".an foo 12",".ic ^^", "Foo (expecting 12): ^(foo)"]
  roff_std ".an (foo) n", [".an (foo) 12",".ic ^^", "Foo (expecting 12): ^(foo)"]
  roff_std ".an foo +1", [".an foo 12",".ic ^^", ".an foo +1", "Foo (expecting 13): ^(foo)"]
  roff_std ".an foo minus 1", [".an foo 12",".ic ^^", ".an foo -1", "Foo (expecting 11): ^(foo)"]
  roff_std ".an foo times 3", [".an foo 12",".ic ^^", ".an foo *3", "Foo (expecting 36): ^(foo)"]
  roff_std ".an foo div 3", [".an foo 12",".ic ^^", ".an foo /3", "Foo (expecting 4): ^(foo)"]
  roff_std ".an foo multiple operators", [".an foo 12",".ic ^^", ".an foo /3-1*8-6", "Foo (expecting 18): ^(foo)"]
  roff_std ".an foo n plus n", [".an foo 12",".ic ^^", ".an foo 14+1", "Foo (expecting 15): ^(foo)"]
  roff_std ".an foo 2 lt 1", [".ic ^^", ".an foo 2<1", "Foo (expecting 0): ^(foo)"]
  roff_std ".an foo 2 eq 1", [".ic ^^", ".an foo 2=1", "Foo (expecting 0): ^(foo)"]
  roff_std ".an foo 2 gt 1", [".ic ^^", ".an foo 2>1", "Foo (expecting 1): ^(foo)"]
  roff_std ".an foo 2 lt 2", [".ic ^^", ".an foo 2<2", "Foo (expecting 0): ^(foo)"]
  roff_std ".an foo 2 eq 2", [".ic ^^", ".an foo 2=2", "Foo (expecting 1): ^(foo)"]
  roff_std ".an foo 2 gt 2", [".ic ^^", ".an foo 2>2", "Foo (expecting 0): ^(foo)"]
  roff_std ".an foo 2 lt 3", [".ic ^^", ".an foo 2<3", "Foo (expecting 1): ^(foo)"]
  roff_std ".an foo 2 eq 3", [".ic ^^", ".an foo 2=3", "Foo (expecting 0): ^(foo)"]
  roff_std ".an foo 2 gt 3", [".ic ^^", ".an foo 2>3", "Foo (expecting 0): ^(foo)"]
  roff_std ".an foo 2 l 3", [".ic ^^", ".an foo 2l3", "Foo (expecting 3): ^(foo)"]
  roff_std ".an foo 2 s 3", [".ic ^^", ".an foo 2s3", "Foo (expecting 2): ^(foo)"]
  roff_std ".an foo string", [".ic ^^", '.qc "', '.an foo "abcd efg"', "Foo (expecting 8): ^(foo)"]
  roff_std "undefined insertion", [".ic ^^", "Foo (expecting 0): ^(foo)"]
  roff_std "insertion in text", [".ic ^^", ".an (xx) 5", "Five is equal to ^(xx)"]
  roff_std "insertion in request", [".ic ^^", ".an (xx) 5", ".sp ^(xx)"]
  roff_std "break after tight concluding punctuation", ["The ] coming up should appear at the end of xxx the line]"]
  roff_std "break in a word with contraction", ["This should not break thee word isn't"]
  roff_std "break before word and concluding punctuation", ["The ] coming up should not appear at start of the xx line]"]
  roff_std "break before word and preceding punctuation", ["The [ coming up should appear at start of the next [line"]
  roff_std "break quoted strings", ['.qc "', 'This text should break the quoted string, "Hello, how are you doing today?"']
  roff_std "hyphenation mode on", ['There should be hyphenation in this text']
  roff_std "hyphenation mode off", ['.hy 0', "There shldn't be hyphenation in this text"]
  roff_std "hyphenate long word", ['.hy 0', "This should break the word supercalifragilisticexpialidocious"]
  roff_std "hyphenate long word 2", ['.hy 0', "This should break the word fddddddddddddddddddddddddddddddddd"]
  roff_std "hyphenate long string", ['.hy 0', "This should break the text 012345678901234567890123456789"]
  roff_std "hyphenate long string 2", ['.hy 0', "This should break the text ]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]"]
  roff_std "hyphenate at hyphen", ["This should break the.. text long-winded at the hyphen"]
  roff_std "hyphenate at hyphenation mark disabled", ["This shouldnt break the text. fdd`dddd`ddd at the mark"]
  roff_std "hyphenate at hyphenation mark", ['.hc `', "This should break the.. text. fdd`dddd`ddd at the mark"]
end