#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Bun::Shell do
  context "write" do
    context "with null file" do
      before :all do
        @shell = Bun::Shell.new
        @stdout_content = capture(:stdout) { @res = @shell.write(nil, "foo") }
      end
      it "should return the text" do
        @res.should == "foo"
      end
      it "should write nothing to $stdout" do
        @stdout_content.should == ""
      end
    end
    context "with - as file" do
      before :all do
        @shell = Bun::Shell.new
        @stdout_content = capture(:stdout) { @res = @shell.write("-", "foo") }
      end
      it "should return the text" do
        @res.should == "foo"
      end
      it "should write the text to $stdout" do
        @stdout_content.should == "foo"
      end
    end
    context "with other file name" do
      before :all do
        @shell = Bun::Shell.new
        @file = "output/test_actual/shell_write_test.txt"
        exec("rm -f #{@file}")
        @res = @shell.write(@file, "foo")
      end
      it "should return the text" do
        @res.should == "foo"
      end
      it "should write the text to the file given" do
        file_should_exist @file
        content = ::File.read(@file)
        content.should == "foo"
      end
      after :all do
        exec("rm -f #{@file}")
      end
    end
  end
end

UNPACK_PATTERNS = {
  :unpack_time=>/:unpack_time: \d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{9} [-+]\d\d:\d\d\s*\n?/,
  :unpacked_by=>/:unpacked_by:\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\s*\n?/, 
}
UNPACK_AND_TIME_PATTERNS = UNPACK_PATTERNS.merge(
  :time=>/:time: \d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{9} [-+]\d\d:\d\d\s*\n?/
)

describe Bun::File::Text do
  include_examples "simple", "ar119.1801"
  include_examples "simple", "ar003.0698"
  
  it "decodes a more complex file (ar004.0642)" do
    infile = 'ar004.0642'
    source_file = infile + Bun::DEFAULT_UNPACKED_FILE_EXTENSION
    outfile = File.join("output", "test_expected", infile)
    decode_and_scrub(source_file, :tabs=>'80').should == rstrip(Bun.readfile(outfile))
  end
end

describe Bun::Archive do
  context "bun unpack" do
    context "to a file that already exists" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar003.0698")
        exec("rm -f output/test_actual/unpack_ar003.0698_stderr")
        exec("echo foo > output/test_actual/unpack_ar003.0698")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun unpack data/test/archive/general_test_packed/ar003.0698 output/test_actual/unpack_ar003.0698 \
              2>output/test_actual/unpack_ar003.0698_stderr", 
              allowed: [1])
      end
      it "should fail" do
        $?.exitstatus.should == 1
      end
      it "should match the expected output on STDERR" do
        "unpack_ar003.0698_stderr".should match_expected_output
      end
      it "should not overwrite the file" do
        "output/test_actual/unpack_ar003.0698".should contain_content("foo")
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
        exec_on_success("rm -f output/test_actual/unpack_ar003.0698_stderr")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
    context "to a file that already exists with --quiet" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar003.0698")
        exec("rm -f output/test_actual/unpack_ar003.0698_stderr")
        exec("echo foo > output/test_actual/unpack_ar003.0698")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun unpack --quiet data/test/archive/general_test_packed/ar003.0698 output/test_actual/unpack_ar003.0698 \
              2>output/test_actual/unpack_ar003.0698_stderr", 
              allowed: [1])
      end
      it "should fail" do
        $?.exitstatus.should == 1
      end
      it "should write nothing on STDERR" do
        "unpack_ar003.0698_stderr".should be_an_empty_file
      end
      it "should not overwrite the file" do
        "output/test_actual/unpack_ar003.0698".should contain_content("foo")
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
        exec_on_success("rm -f output/test_actual/unpack_ar003.0698_stderr")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
    context "to a file that already exists with --force" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar003.0698")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("echo foo > output/test_actual/unpack_ar003.0698")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun unpack --force data/test/archive/general_test_packed/ar003.0698 output/test_actual/unpack_ar003.0698")
      end
      it "should match the expected output" do
        "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
    context "with a text file" do
      context "with output to '-'" do
        before :all do
          exec("rm -f output/test_actual/unpack_ar003.0698")
          exec("rm -rf data/test/archive/general_test_packed")
          exec("cp -r data/test/archive/general_test_packed_init \
                      data/test/archive/general_test_packed")
          exec("bun unpack data/test/archive/general_test_packed/ar003.0698 - \
                    >output/test_actual/unpack_ar003.0698")
        end
        it "should match the expected output" do
          "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
          exec_on_success("rm -rf data/test/archive/general_test_packed")
        end
      end
      context "with omitted output" do
        before :all do
          exec("rm -f output/test_actual/unpack_ar003.0698")
          exec("rm -rf data/test/archive/general_test_packed")
          exec("cp -r data/test/archive/general_test_packed_init \
                   data/test/archive/general_test_packed")
          exec("bun unpack data/test/archive/general_test_packed/ar003.0698 >output/test_actual/unpack_ar003.0698")
        end
        it "should match the expected output" do
          "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
          exec_on_success("rm -rf data/test/archive/general_test_packed")
        end
      end
      context "from STDIN" do
        context "without tape name" do
          before :all do
            exec("rm -rf output/test_actual/unpack_stdin_ar003.0698")
            exec("rm -rf data/test/archive/general_test_packed")
            exec("cp -r data/test/archive/general_test_packed_init \
                    data/test/archive/general_test_packed")
            exec("cat data/test/archive/general_test_packed/ar003.0698 | \
                    bun unpack - >output/test_actual/unpack_stdin_ar003.0698")
          end
          it "should match the expected output" do
            "unpack_stdin_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
          end
          after :all do
            backtrace
            exec_on_success("rm -rf output/test_actual/unpack_stdin_ar003.0698")
            exec_on_success("rm -rf data/test/archive/general_test_packed")
          end
        end
        context "with tape name" do
          before :all do
            exec("rm -f output/test_actual/unpack_ar003.0698")
            exec("rm -rf data/test/archive/general_test_packed")
            exec("cp -r data/test/archive/general_test_packed_init \
                    data/test/archive/general_test_packed")
            exec("cat data/test/archive/general_test_packed/ar003.0698 | \
                    bun unpack -t ar003.0698 - >output/test_actual/unpack_ar003.0698")
          end
          it "should match the expected output" do
            "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
          end
          after :all do
            backtrace
            exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
            exec_on_success("rm -rf data/test/archive/general_test_packed")
          end
        end
      end
      context "with output to a file" do
        before :all do
          exec("rm -f output/test_actual/unpack_ar003.0698")
          exec("rm -rf data/test/archive/general_test_packed")
          exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
          exec("bun unpack data/test/archive/general_test_packed/ar003.0698 output/test_actual/unpack_ar003.0698")
        end
        it "should match the expected output" do
          "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
          exec_on_success("rm -rf data/test/archive/general_test_packed")
        end
      end
    end
    context "with a frozen file" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar019.0175")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun unpack data/test/archive/general_test_packed/ar019.0175 output/test_actual/unpack_ar019.0175")
      end
      it "should match the expected output" do
        "unpack_ar019.0175".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar019.0175")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
    context "with a huffman file" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar003.0701")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun unpack data/test/archive/general_test_packed/ar003.0701 output/test_actual/unpack_ar003.0701")
      end
      it "should match the expected output" do
        "unpack_ar003.0701".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar003.0701")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
    context "with a file with a bad time" do
      context "without --fix" do
        before :all do
          exec("rm -f output/test_actual/unpack_packed_with_bad_time")
          exec("rm -f output/test_actual/unpack_packed_with_bad_time_stderr.txt")
          exec("bun unpack data/test/packed_with_bad_time output/test_actual/unpack_packed_with_bad_time \
                    2>output/test_actual/unpack_packed_with_bad_time_stderr.txt", 
                allowed: [1])
        end
        it "should fail" do
          $?.exitstatus.should == 1
        end
        it "should not create the file" do
          file_should_not_exist("output/test_actual/unpack_packed_with_bad_time")
        end
        it "should write diagnostics on STDERR" do
          "unpack_packed_with_bad_time_stderr.txt".should match_expected_output
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_time")
          exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_time_stderr.txt")
        end
      end
      context "with --fix" do
        before :all do
          exec("rm -f output/test_actual/unpack_packed_with_bad_time")
          exec("rm -f output/test_actual/unpack_packed_with_bad_time_stderr.txt")
          @before_time = Time.now
          exec("bun unpack --fix data/test/packed_with_bad_time output/test_actual/unpack_packed_with_bad_time \
                    2>output/test_actual/unpack_packed_with_bad_time_stderr.txt")
          @after_time = Time.now
        end
        it "should create the file" do
          "unpack_packed_with_bad_time".should match_expected_output_except_for(UNPACK_AND_TIME_PATTERNS)
        end
        it "should have today's date" do
          time_string = `bun show time output/test_actual/unpack_packed_with_bad_time`.chomp
          file_date = Date.strptime(time_string[0,10])
          file_date.should be >= @before_time.to_date
          file_date.should be <= @after_time.to_date
        end
        it "should write nothing on STDERR" do
          "output/test_actual/unpack_packed_with_bad_time_stderr.txt".should be_an_empty_file
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_time")
          exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_time_stderr.txt")
        end
      end
    end
    context "with a file with a bad bcw" do
      context "without --fix" do
        before :all do
          exec("rm -f output/test_actual/unpack_packed_with_bad_bcw")
          exec("rm -f output/test_actual/unpack_packed_with_bad_bcw_stderr.txt")
          exec("bun unpack data/test/packed_with_bad_bcw output/test_actual/unpack_packed_with_bad_bcw \
                    2>output/test_actual/unpack_packed_with_bad_bcw_stderr.txt", 
                allowed: [1])
        end
        it "should fail" do
          $?.exitstatus.should == 1
        end
        it "should not create the file" do
          file_should_not_exist("output/test_actual/unpack_packed_with_bad_bcw")
        end
        it "should write diagnostics on STDERR" do
          "unpack_packed_with_bad_bcw_stderr.txt".should match_expected_output
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_bcw")
          exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_bcw_stderr.txt")
        end
      end
      context "with --fix" do
        before :all do
          exec("rm -f output/test_actual/unpack_packed_with_bad_bcw")
          exec("rm -f output/test_actual/unpack_packed_with_bad_bcw_fix_stderr.txt")
          exec("bun unpack --fix data/test/packed_with_bad_bcw output/test_actual/unpack_packed_with_bad_bcw \
                    2>output/test_actual/unpack_packed_with_bad_bcw_fix_stderr.txt")
        end
        it "should create the file" do
          "unpack_packed_with_bad_bcw".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        it "should write a message on STDERR" do
          "unpack_packed_with_bad_bcw_fix_stderr.txt".should match_expected_output
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_bcw")
          exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_bcw_fix_stderr.txt")
        end
      end
    end
  end
  
  context "bun archive unpack" do
    context "normal" do
      before :all do
        exec("rm -rf data/test/archive/general_test_packed_unpacked")
        exec("rm -f output/test_actual/archive_unpack_files.txt")
        exec("rm -f output/test_actual/archive_unpack_stdout.txt")
        exec("rm -f output/test_actual/archive_unpack_stdout.txt")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun archive unpack data/test/archive/general_test_packed \
                data/test/archive/general_test_packed_unpacked 2>output/test_actual/archive_unpack_stderr.txt \
                >output/test_actual/archive_unpack_stdout.txt")
      end
      it "should create a new directory" do
        file_should_exist "data/test/archive/general_test_packed_unpacked"
      end
      it "should write nothing on stdout" do
        'output/test_actual/archive_unpack_stdout.txt'.should be_an_empty_file
      end
      it "should write file decoding messages on stderr" do
        "archive_unpack_stderr.txt".should match_expected_output
      end
      it "should create the appropriate files" do
        exec('find data/test/archive/general_test_packed_unpacked -print \
                  >output/test_actual/archive_unpack_files.txt')
        "archive_unpack_files.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
        exec_on_success("rm -f output/test_actual/archive_unpack_files.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_stdout.txt")
      end
    end
    context "with --quiet" do
      before :all do
        exec("rm -rf data/test/archive/general_test_packed_unpacked")
        exec("rm -f output/test_actual/archive_unpack_files.txt")
        exec("rm -f output/test_actual/archive_unpack_stdout.txt")
        exec("rm -f output/test_actual/archive_unpack_stderr.txt")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun archive unpack --quiet data/test/archive/general_test_packed \
                data/test/archive/general_test_packed_unpacked 2>output/test_actual/archive_unpack_stderr.txt \
                >output/test_actual/archive_unpack_stdout.txt")
      end
      it "should create a new directory" do
        file_should_exist "data/test/archive/general_test_packed_unpacked"
      end
      it "should write nothing on stdout" do
        'output/test_actual/archive_unpack_stdout.txt'.should be_an_empty_file
      end
      it "should write nothing on stderr" do
        "archive_unpack_stderr.txt".should be_an_empty_file
      end
      it "should create the appropriate files" do
        exec('find data/test/archive/general_test_packed_unpacked -print \
                  >output/test_actual/archive_unpack_files.txt')
        "archive_unpack_files.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
        exec_on_success("rm -f output/test_actual/archive_unpack_files.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_stdout.txt")
      end
    end
    context "to existing directory" do
      before :all do
        exec("rm -rf data/test/archive/general_test_packed_unpacked")
        exec("rm -f output/test_actual/archive_unpack_existing_directory_files.txt")
        exec("rm -f output/test_actual/archive_unpack_stdout.txt")
        exec("rm -f output/test_actual/archive_unpack_stderr.txt")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("mkdir data/test/archive/general_test_packed_unpacked")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun archive unpack data/test/archive/general_test_packed \
                data/test/archive/general_test_packed_unpacked 2>output/test_actual/archive_unpack_stderr.txt \
                >output/test_actual/archive_unpack_stdout.txt", allowed: [1])
        @exitstatus = $?.exitstatus
        exec("find data/test/archive/general_test_packed_unpacked -print \
                >output/test_actual/archive_unpack_existing_directory_files.txt")
      end
      it "should fail" do
        @exitstatus.should == 1
      end
      it "should not create any files" do
        'archive_unpack_existing_directory_files.txt'.should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
        exec_on_success("rm -f output/test_actual/archive_unpack_existing_directory_files.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_stdout.txt")
      end
    end
    context "to existing directory with --force" do
      before :all do
        exec("rm -rf data/test/archive/general_test_packed_unpacked")
        exec("rm -f output/test_actual/archive_unpack_files.txt")
        exec("rm -f output/test_actual/archive_unpack_stdout.txt")
        exec("rm -f output/test_actual/archive_unpack_stderr.txt")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("mkdir data/test/archive/general_test_packed_unpacked")
        exec("bun archive unpack --force data/test/archive/general_test_packed \
                data/test/archive/general_test_packed_unpacked 2>output/test_actual/archive_unpack_stderr.txt \
                >output/test_actual/archive_unpack_stdout.txt")
      end
      it "should write nothing on stdout" do
        'output/test_actual/archive_unpack_stdout.txt'.should be_an_empty_file
      end
      it "should write file decoding messages on stderr" do
        "archive_unpack_stderr.txt".should match_expected_output
      end
      it "should create the appropriate files" do
        exec('find data/test/archive/general_test_packed_unpacked -print \
                  >output/test_actual/archive_unpack_files.txt')
        "archive_unpack_files.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
        exec_on_success("rm -f output/test_actual/archive_unpack_files.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_stdout.txt")
      end
    end
    context "with --flatten" do
      before :all do
        exec("rm -rf data/test/archive/general_test_packed_unpacked_flatten")
        exec("rm -f output/test_actual/archive_unpack_flatten_files.txt")
        exec("rm -f output/test_actual/archive_unpack_flatten_stdout.txt")
        exec("rm -f output/test_actual/archive_unpack_flatten_stderr.txt")
        exec("bun archive unpack --flatten data/test/archive/packed_with_subdirectories \
                data/test/archive/general_test_packed_unpacked_flatten \
                2>output/test_actual/archive_unpack_flatten_stderr.txt \
                >output/test_actual/archive_unpack_flatten_stdout.txt")
      end
      it "should create a new directory" do
        file_should_exist "data/test/archive/general_test_packed_unpacked_flatten"
      end
      it "should write nothing on stdout" do
        'output/test_actual/archive_unpack_flatten_stdout.txt'.should be_an_empty_file
      end
      it "should write file decoding messages on stderr" do
        "archive_unpack_flatten_stderr.txt".should match_expected_output
      end
      it "should create the appropriate files" do
        exec('find data/test/archive/general_test_packed_unpacked_flatten -print \
                  >output/test_actual/archive_unpack_flatten_files.txt')
        "archive_unpack_flatten_files.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked_flatten")
        exec_on_success("rm -f output/test_actual/archive_unpack_flatten_files.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_flatten_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_flatten_stdout.txt")
      end
    end
  end
end

describe Bun::Archive do
  before :each do
    @archive = Bun::Archive.new('data/test/archive/contents')
    $expected_archive_contents = %w{
      ar003.0698.bun
      ar054.2299.bun[brytside]
      ar054.2299.bun[disco]
      ar054.2299.bun[end]
      ar054.2299.bun[opening]
      ar054.2299.bun[santa] 
    } 
  end
  describe "contents" do
    it "retrieves correct list" do
      @archive.contents.sort.should == $expected_archive_contents
    end
    it "invokes a block" do
      foo = []
      @archive.contents {|f| foo << f.upcase }
      foo.sort.should == $expected_archive_contents.map{|c| c.upcase }
    end
    after :all do
      backtrace
    end
  end
end

# Frozen files to check ar013.0560, ar004.0888, ar019.0175

DESCRIBE_PATTERNS = {
  :unpack_time=>/Unpack Time\s+\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\s+[-+]\d{4}\n?/,
  :unpacked_by=>/Unpacked By\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\n?/,
}

DESCRIBE_WITH_DECODE_PATTERNS = {
  :unpack_time=>/Unpack Time\s+\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\s+[-+]\d{4}\n?/,
  :unpacked_by=>/Unpacked By\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\n?/,
  :decode_time=>/Decode Time\s+\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\s+[-+]\d{4}\n?/,
  :decoded_by =>/Decoded By\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\n?/,
}

DECODE_PATTERNS = {
  :unpack_time=>/:unpack_time: \d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{9} [-+]\d\d:\d\d\n?/,
  :unpacked_by=>/:unpacked_by:\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\n?/, 
  :decode_time=>/:decode_time: \d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{9} [-+]\d\d:\d\d\n?/,
  :decoded_by=>/:decoded_by:\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\n?/, 
}

describe Bun::Bot do
  # include_examples "command", "descr", "cmd", "expected_stdout_file"
  # include_examples "command with file", "descr", "cmd", "expected_stdout_file", "output_in_file", "expected_output_file"
  describe "scrub" do
    include_examples "command", "scrub", "scrub data/test/clean", "scrub"
    include_examples "command from STDIN", 
                     "scrub", 
                     "scrub -",
                     "data/test/clean", 
                     "scrub"
    after :all do
      backtrace
    end
  end

  describe "fields" do
    [
      {
        :title=>"no options",
        :command=>"fields"
      },
      {
        :title=>"-l option",
        :command=>"fields -l"
      },
      {
        :title=>"with pattern",
        :command=>"fields time"
      },
      {
        :title=>"with pattern and -l",
        :command=>"fields time -l"
      },
    ].each do |test|
      exec_test_hash "fields", test
    end
  end

  describe "traits" do
    [
      {
        :title=>"no options",
        :command=>"traits"
      },
      {
        :title=>"-l option",
        :command=>"traits -l"
      },
      {
        :title=>"-o option",
        :command=>"traits -o"
      },
      {
        :title=>"with pattern",
        :command=>"traits c"
      },
      {
        :title=>"with pattern and -o",
        :command=>"traits c -o"
      },
    ].each do |test|
      exec_test_hash "traits", test
    end
  end

  describe "show" do
    context "basic tests" do
      include_examples "command", "show clean file", "show --asis clean data/test/clean", "show_clean"
      include_examples "command from STDIN", "show clean file", 
          "show --asis clean -", "data/test/clean", "show_clean"
      
      # Dirty file is just the packed version of ar119.1801
      include_examples "command", "show dirty file", "show --asis clean data/test/dirty", "show_dirty",
                       :allowed=>[1]
      include_examples "command", "show promotes file", 
        "show clean data/test/packed_ar003.0698", "show_clean",
                         :allowed=>[1] # Because we're testing the output; it's more helpful
                                       # to allow a non-zero return code
      include_examples "command", "show does not promote file with --asis", 
        "show --asis clean data/test/packed_ar003.0698", "show_dirty",
                         :allowed=>[1]
      after :all do
        backtrace
      end
    end

    %w{ar003.0698 ar025.0634}.each do |file|
      context "all tests on #{file}" do
        String::Trait.traits.each do |trait|
          @current_exam = trait
          context @current_exam do
            before :all do
              @show_result_file = "show_#{trait}_#{file}"
              exec("rm -rf output/test_actual/#{@show_result_file}")
              exec("bun show file #{trait} --raise -j --titles --in #{TEST_ARCHIVE}/#{file}.bun >output/test_actual/#{@show_result_file}", :allowed=>[0,1])
            end
            it "should produce the proper output" do
              @show_result_file.should match_expected_output
            end
            after :all do
              backtrace
              exec_on_success("rm -rf output/test_actual/#{@show_result_file}")
            end
          end
        end
      end
    end
    context "specific tests" do
      [
        {
          title:   "field[] syntax with symbol", 
          command: "show 'field[:first_block_size]' data/test/ar003.0698.bun"
        },
        {
          title:   "field[] syntax with string", 
          command: %Q{show 'field["first_block_size"]' data/test/ar003.0698.bun}
        },
        {
          title:   "trait[] syntax with symbol", 
          command: "show 'trait[:legibility]' data/test/ar003.0698.bun"
        },
        {
          title:   "trait[] syntax with string", 
          command: %Q{show 'trait["legibility"]' data/test/ar003.0698.bun}
        },
        {
          title:   "matrix result without file, --titles, or --justify", 
          command: "show 'chars' data/test/ar003.0698.bun"
        },
        {
          title:   "matrix result with --titles without file or --justify", 
          command: "show file 'chars' --in data/test/ar003.0698.bun --titles"
        },
        {
          title:   "matrix result --format csv", 
          command: "show 'chars' data/test/ar003.0698.bun --format csv"
        },
        {
          title:   "multiple files without --titles", 
          command: "show 'chars' data/test/ar003.0698.bun data/test/ar019.0175.bun"
        },
        {
          title:   "complex formula with field and right coercion", 
          command: "show 'first_block_size*2' data/test/ar003.0698.bun"
        },
        {
          title:   "complex formula with field and left coercion", 
          command: "show '1 + first_block_size' data/test/ar003.0698.bun"
        },
        {
          title:   "complex formula with trait and right coercion", 
          command: "show 'legibility*2' data/test/ar003.0698.bun"
        },
        {
          title:   "complex formula with trait and left coercion", 
          command: "show '1 + legibility' data/test/ar003.0698.bun"
        },
        {
          title:   "bad formula with matrix trait", 
          command: "show 'classes+1' data/test/ar003.0698.bun",
          fail:    true
        },
        {
          title:   "field", 
          command: "show digest data/test/ar003.0698.bun"
        },
        {
          title:   "earliest_time",
          command: "show 'earliest_time' data/test/ar003.0698.bun"
        },
        {
          title:   "low legibility, not roff", 
          command: "show legibility roff --in data/test/ar047.1383.bun"
        },
        {
          title:   "text", 
          command: "show text data/test/ar003.0698.bun"
        },
        {
          title:   "file", 
          command: "show file data/test/ar003.0698.bun"
        },
        {
          title:    "tabbed",
          command: "show tabbed data/test/ar019.0175.bun",
          allowed: [1]
        },
        {
          title:    "listing with print file",
          command: "show listing data/test/ar074.1174.bun[1.3b]",
          allowed: [1]
        },
        {
          title:   "words with minimum 5", 
          command: "show 'words(minimum: 5)' data/test/ar003.0698.bun"
        },
        {
          title:   "case insensitive words", 
          command: "show 'words(case_insensitive: true)' data/test/ar003.0698.bun"
        },
        {
          title:   "inspect frozen file shards",
          command: "show 'shards.inspect' data/test/ar019.0175.bun"
        },
        {
          title:   "shards for non-frozen file", 
          command: "show shards data/test/ar003.0698.bun" # Should be nil (or maybe [])
        },
        {
          title:   "second shard name",
          command: "show 'shards[1][:name]' data/test/ar019.0175.bun"
        },
        {
          title:   "second shard time, indexed by name, field indexed",
          command: "show 'shards[\"eclipse\"][:time]' data/test/ar019.0175.bun"
        },
        {
          title:   "second shard time, indexed by name, field method",
          command: "show 'shards[\"eclipse\"].time' data/test/ar019.0175.bun"
        },
        {
          title:   "second shard size, indexed by name, field method",
          command: "show 'shards[\"eclipse\"].size' data/test/ar019.0175.bun" # Should be 6614, not 5
        },
        {
          title:   "fields from file with specified shard number",
          command: "show fields data/test/ar019.0175.bun[+2]"
        },
        {
          title:   "field from file with specified shard number",
          command: "show 'shard_name' data/test/ar019.0175.bun[+2]"
        },
        {
          title:   "earliest_time from file with specified shard number",
          command: "show 'earliest_time' data/test/ar019.0175.bun[+2]"
        },
        {
          title:   "field from file with specified shard name",
          command: "show 'shard_start' data/test/ar019.0175.bun[eclipse]"
        },
        {
          title:   "text from file with specified shard name",
          command: "show text data/test/ar019.0175.bun[eclipse]"
        },
        {
          title:   "--if parameter 1", # matches
          command: "show fields data/test/ar019.0175.bun[+2] --if 'type==:frozen'"
        },
        {
          title:   "--if parameter 2", # does not match
          command: "show fields data/test/ar019.0175.bun[+2] --if 'type!=:frozen'"
        },
        {
          title:   "--where parameter", # does not match
          command: "show fields data/test/ar019.0175.bun[+2] --where 'type!=:frozen'"
        },
        {
          title:   "--unless parameter", # does not match
          command: "show fields data/test/ar019.0175.bun[+2] --unless 'type==:frozen'"
        },
        {
          title:   "--order parameter",
          command: "show tape_size data/test/archive/general_test --order 'desc:tape_size' -j"
        },
        {
          title:   "bad field or trait",
          command: "show foo data/test/ar019.0175.bun[eclipse]",
          fail:    true
        },
        {
          title:   "bad trait parameters",
          command: "show 'words(:foo=>true)' data/test/ar019.0175.bun[eclipse]",
          fail:    true
        },
        {
          title:   "bad formula",
          command: "show '2*' data/test/ar019.0175.bun[eclipse]",
          fail:    true
        },
      ].each do |test|
        exec_test_hash "show_specific_test", test
      end
    end
  end
    
  describe "describe" do
    describe "with text file" do
      before :all do
        exec("rm -rf output/test_actual/describe_ar003.0698")
        exec("bun describe #{TEST_ARCHIVE}/ar003.0698.bun >output/test_actual/describe_ar003.0698")
      end
      it "should match the expected output" do
        "describe_ar003.0698".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -rf output/test_actual/describe_ar003.0698")
      end
    end
    describe "with frozen file" do
      before :all do
        exec("rm -rf output/test_actual/describe_ar025.0634")
        exec("bun describe #{TEST_ARCHIVE}/ar025.0634.bun >output/test_actual/describe_ar025.0634")
      end
      it "should match the expected output (including quoting)" do
        "describe_ar025.0634".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -rf output/test_actual/describe_ar025.0634")
      end
    end

    context "functioning outside the base directory" do
      before :each do
        raise RuntimeError, "In unexpected working directory: #{Dir.pwd}" \
          unless File.expand_path(Dir.pwd) == File.expand_path(File.join(File.dirname(__FILE__),'..'))
        @original_dir = Dir.pwd
      end
      it "should start in the base directory" do
        File.expand_path(Dir.pwd).should == File.expand_path(File.join(File.dirname(__FILE__),'..'))
      end
      it "should function okay in a different directory" do
        exec("cd ~ ; bun describe #{TEST_ARCHIVE}/ar003.0698.bun")
        $?.exitstatus.should == 0
      end
      after :each do
        Dir.chdir(@original_dir)
        raise RuntimeError, "Not back in normal working directory: #{Dir.pwd}" \
          unless File.expand_path(Dir.pwd) == File.expand_path(File.join(File.dirname(__FILE__),'..'))
      end
      after :all do
        backtrace
      end
    end
  end  
  
  describe "mark" do
    context "with no output file" do
      before :all do
        exec "rm -f data/test/mark_source.bun"
        exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
        exec "bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
      end
      it "should have the expected input" do
        "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should create the expected marks in the existing file" do
        "mark_source_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success "rm -f data/test/mark_source.bun"
        exec_on_success "rm -f output/test_actual/mark_source_before"
        exec_on_success "rm -f output/test_actual/mark_source_after"
      end
    end
    context "with an output file" do
      before :all do
        exec "rm -f data/test/mark_source.bun"
        exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
        exec "rm -f data/test/mark_result.bun"
        exec "bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" \
                  data/test/mark_source.bun data/test/mark_result.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
        exec "bun describe data/test/mark_result.bun >output/test_actual/mark_result_after"
      end
      it "should have the expected input" do
        "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should create the new file" do
        file_should_exist "data/test/mark_result.bun"
      end
      it "should create the expected marks in the new file" do
        "mark_result_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should have leave the existing file unchanged" do
        "output/test_actual/mark_source_after".should match_file('output/test_actual/mark_source_before')
      end
      after :all do
        backtrace
        exec_on_success "rm -f data/test/mark_source.bun"
        exec_on_success "rm -f data/test/mark_result.bun"
        exec_on_success "rm -f output/test_actual/mark_source_before"
        exec_on_success "rm -f output/test_actual/mark_source_after"
        exec_on_success "rm -f output/test_actual/mark_result_after"
      end
    end
    context "with '-' as output file" do
      before :all do
        exec "rm -f data/test/mark_source.bun"
        exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
        exec "rm -f output/test_actual/mark_result.bun"
        exec "bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" \
                  data/test/mark_source.bun - >output/test_actual/mark_result.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
        exec "bun describe output/test_actual/mark_result.bun >output/test_actual/mark_result_after"
      end
      it "should have the expected input" do
        "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should create the expected marks on STDOUT" do
        "mark_result_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should have leave the existing file unchanged" do
        "output/test_actual/mark_source_after".should match_file('output/test_actual/mark_source_before')
      end
      after :all do
        backtrace
        exec_on_success "rm -f data/test/mark_source.bun"
        exec_on_success "rm -f output/test_actual/mark_result.bun"
        exec_on_success "rm -f output/test_actual/mark_source_before"
        exec_on_success "rm -f output/test_actual/mark_source_after"
        exec_on_success "rm -f output/test_actual/mark_result_after"
      end
    end
    context "with '-' as input file" do
      before :all do
        exec "rm -f data/test/mark_source.bun"
        exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
        exec "rm -f data/test/mark_result.bun"
        exec "cat data/test/mark_source.bun | \
              bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" \
                  - data/test/mark_result.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
        exec "bun describe data/test/mark_result.bun >output/test_actual/mark_result_after"
      end
      it "should have the expected input" do
        "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should create the new file" do
        file_should_exist "data/test/mark_result.bun"
      end
      it "should create the expected marks in the new file" do
        "mark_result_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should have leave the existing file unchanged" do
        "output/test_actual/mark_source_after".should match_file('output/test_actual/mark_source_before')
      end
      after :all do
        backtrace
        exec_on_success "rm -f data/test/mark_source.bun"
        exec_on_success "rm -f data/test/mark_result.bun"
        exec_on_success "rm -f output/test_actual/mark_source_before"
        exec_on_success "rm -f output/test_actual/mark_source_after"
        exec_on_success "rm -f output/test_actual/mark_result_after"
      end
    end
  end
  
  describe "ls" do
    include_examples "command", "ls", "ls #{TEST_ARCHIVE}", "ls"
    include_examples "command", "ls -o", "ls -o #{TEST_ARCHIVE}", "ls_o"
    include_examples "command", 
                     "ls -ldr with text file (ar003.0698)", 
                     "ls -ldr #{TEST_ARCHIVE}/ar003.0698.bun", 
                     "ls_ldr_ar003.0698"
    include_examples "command", 
                     "ls -ldr with frozen file (ar145.2699)", 
                     "ls -ldr #{TEST_ARCHIVE}/ar145.2699.bun", 
                     "ls_ldr_ar145.2699"
    include_examples "command", "ls with glob", "ls #{TEST_ARCHIVE}/ar08*", "ls_glob"
    after :all do
      backtrace
    end
  end

  describe "readme" do
    include_examples "command", "readme", "readme", "doc/readme.md"
    after :all do
      backtrace
    end
  end

  describe "decode" do
    context "with baked file" do
      before :all do
        exec("rm -f output/test_actual/decode_baked")
        exec("rm -f output/test_actual/decode_baked_stderr")
        exec("bun decode data/test/archive/mixed_formats/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt \
                  2>output/test_actual/decode_baked_stderr \
                  >output/test_actual/decode_baked", allowed: [1])
      end
      it "should fail" do
        $?.exitstatus.should == 1
      end
      it "should not write output" do
        "decode_baked".should be_an_empty_file
      end
      it "should write the expected message on STDERR" do
        "decode_baked_stderr".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_baked")
        exec_on_success("rm -f output/test_actual/decode_baked_stderr")
      end
    end
   context "with baked file and --quiet" do
      before :all do
        exec("rm -f output/test_actual/decode_baked")
        exec("rm -f output/test_actual/decode_baked_stderr")
        exec("bun decode --quiet data/test/archive/mixed_formats/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt \
                  2>output/test_actual/decode_baked_stderr \
                  >output/test_actual/decode_baked", allowed: [1])
      end
      it "should fail" do
        $?.exitstatus.should == 1
      end
      it "should not write output" do
        "decode_baked".should be_an_empty_file
      end
      it "should write nothing on STDERR" do
        "decode_baked_stderr".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_baked")
        exec_on_success("rm -f output/test_actual/decode_baked_stderr")
      end
    end
    context "with text file" do
      context "without expand option" do
        before :all do
          exec("rm -f output/test_actual/decode_ar003.0698")
          exec("bun decode #{TEST_ARCHIVE}/ar003.0698.bun \
                    >output/test_actual/decode_ar003.0698")
        end
        it "should match the expected output" do
          "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/decode_ar003.0698")
        end
      end
      context "with expand option" do
        before :all do
          exec("rm -f output/test_actual/decode_ar003.0698")
          exec("bun decode --expand #{TEST_ARCHIVE}/ar003.0698.bun \
                    >output/test_actual/decode_ar003.0698")
        end
        it "should match the expected output" do
          "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/decode_ar003.0698")
        end
      end
      context "from STDIN" do
        before :all do
          exec("rm -f output/test_actual/decode_ar003.0698")
          exec("cat #{TEST_ARCHIVE}/ar003.0698.bun | bun decode - \
                    >output/test_actual/decode_ar003.0698")
        end
        it "should match the expected output" do
          "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/decode_ar003.0698")
        end
      end
      context "with existing file" do
        before :all do
          exec("rm -f output/test_actual/decode_ar003.0698")
          exec("rm -f output/test_actual/decode_ar003.0698_existing_stderr.txt")
          exec("echo foo >output/test_actual/decode_ar003.0698")
          exec("bun decode #{TEST_ARCHIVE}/ar003.0698.bun \
                    output/test_actual/decode_ar003.0698 \
                    2>output/test_actual/decode_ar003.0698_existing_stderr.txt", allowed: [1])
        end
        it "should fail" do
          $?.exitstatus.should == 1
        end
        it "should not overwrite the existing file" do
          "output/test_actual/decode_ar003.0698".should contain_content('foo')
        end
        it "should write appropriate messages on STDERR" do
          "decode_ar003.0698_existing_stderr.txt".should match_expected_output
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/decode_ar003.0698")
          exec_on_success("rm -f output/test_actual/decode_ar003.0698_existing_stderr.txt")
        end
      end
      context "with existing file and --quiet" do
        before :all do
          exec("rm -f output/test_actual/decode_ar003.0698")
          exec("rm -f output/test_actual/decode_ar003.0698_existing_stderr.txt")
          exec("echo foo >output/test_actual/decode_ar003.0698")
          exec("bun decode --quiet #{TEST_ARCHIVE}/ar003.0698.bun \
                    output/test_actual/decode_ar003.0698 \
                    2>output/test_actual/decode_ar003.0698_existing_stderr.txt", allowed: [1])
        end
        it "should fail" do
          $?.exitstatus.should == 1
        end
        it "should not overwrite the existing file" do
          "output/test_actual/decode_ar003.0698".should contain_content('foo')
        end
        it "should write nothing on STDERR" do
          "output/test_actual/decode_ar003.0698_existing_stderr.txt".should be_an_empty_file
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/decode_ar003.0698")
          exec_on_success("rm -f output/test_actual/decode_ar003.0698_existing_stderr.txt")
        end
      end
      context "with existing file and --force" do
        before :all do
          exec("rm -f output/test_actual/decode_ar003.0698")
          exec("echo foo >output/test_actual/decode_ar003.0698")
          exec("bun decode --force #{TEST_ARCHIVE}/ar003.0698.bun \
                    output/test_actual/decode_ar003.0698")
        end
        it "should match the expected output" do
          "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/decode_ar003.0698")
        end
      end
    end
    context "with huffman file" do
      before :all do
        exec("rm -f output/test_actual/decode_ar003.0701")
        exec("bun decode #{TEST_ARCHIVE}/ar003.0701.bun \
                  >output/test_actual/decode_ar003.0701")
      end
      it "should match the expected output" do
        "decode_ar003.0701".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_ar003.0701")
      end
    end
    context "with frozen file" do
      context "and +0 shard argument" do
        before :all do
          exec("rm -rf output/test_actual/decode_ar004.0888_0")
          exec("bun decode -S +0 #{TEST_ARCHIVE}/ar004.0888.bun \
                    >output/test_actual/decode_ar004.0888_0")
        end
        it "should match the expected output" do
          "decode_ar004.0888_0".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -rf output/test_actual/decode_ar004.0888_0")
        end
      end
      context "and [+0] shard syntax" do
        before :all do
          exec("rm -rf output/test_actual/decode_ar004.0888_0")
          exec("bun decode #{TEST_ARCHIVE}/ar004.0888.bun[+0] \
                    >output/test_actual/decode_ar004.0888_0")
        end
        it "should match the expected output" do
          "decode_ar004.0888_0".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -rf output/test_actual/decode_ar004.0888_0")
        end
      end
      context "and [name] shard syntax" do
        before :all do
          exec("rm -rf output/test_actual/decode_ar004.0888_0")
          exec("bun decode #{TEST_ARCHIVE}/ar004.0888.bun[fasshole] \
                    >output/test_actual/decode_ar004.0888_0")
        end
        it "should match the expected output" do
          "decode_ar004.0888_0".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -rf output/test_actual/decode_ar004.0888_0")
        end
      end
      context "and [name] shard syntax with --scrub" do
        before :all do
          exec("rm -rf output/test_actual/decode_ar074.1174_1.3b_scrub")
          exec("bun decode --scrub data/test/ar074.1174.bun[1.3b] \
                    >output/test_actual/decode_ar074.1174_1.3b_scrub")
        end
        it "should match the expected output" do
          "decode_ar074.1174_1.3b_scrub".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -rf output/test_actual/decode_ar074.1174_1.3b_scrub")
        end
      end
      context "and no shard argument" do
        context "and no expand option" do
          before :all do
            exec("rm -rf output/test_actual/decode_ar004.0888")
            exec("bun decode #{TEST_ARCHIVE}/ar004.0888.bun \
                      2>/dev/null >output/test_actual/decode_ar004.0888", :allowed=>[1])
          end
          it "should fail" do
            $?.exitstatus.should == 1
          end
          after :all do
            backtrace
            exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
          end
        end
        context "and expand option" do
          context "without output file name" do
            before :all do
              exec("rm -rf output/test_actual/decode_ar004.0888")
              exec("bun decode --expand #{TEST_ARCHIVE}/ar004.0888.bun \
                        2>/dev/null >output/test_actual/decode_ar004.0888", :allowed=>[1])
            end
            it "should fail" do
              $?.exitstatus.should == 1
            end
            after :all do
              backtrace
              exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
            end
          end
          context "with '-' as output file name" do
            before :all do
              exec("rm -rf output/test_actual/decode_ar004.0888")
              exec("bun decode --expand #{TEST_ARCHIVE}/ar004.0888.bun - \
                        2>/dev/null >output/test_actual/decode_ar004.0888", :allowed=>[1])
            end
            it "should fail" do
              $?.exitstatus.should == 1
            end
            after :all do
              backtrace
              exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
            end
          end
          context "with output file name" do
            before :all do
              exec("rm -rf output/test_actual/decode_ar004.0888")
              exec("rm -rf output/test_actual/decode_ar004.0888.ls.txt")
              exec("rm -rf output/test_actual/decode_ar004.0888_cat_3eleven.txt")
              exec("bun decode --expand #{TEST_ARCHIVE}/ar004.0888.bun \
                        output/test_actual/decode_ar004.0888")
            end
            it "should create a directory" do
              system('[ -d output/test_actual/decode_ar004.0888 ]').should be_true
            end
            it "should contain all the shards" do
              exec("ls output/test_actual/decode_ar004.0888 >output/test_actual/decode_ar004.0888.ls.txt")
              "decode_ar004.0888.ls.txt".should match_expected_output
            end
            it "should match the expected output in the shards" do
              exec("cat output/test_actual/decode_ar004.0888/3eleven >output/test_actual/decode_ar004.0888_cat_3eleven.txt")
              "decode_ar004.0888_cat_3eleven.txt".should match_expected_output_except_for(DECODE_PATTERNS)
            end
            after :all do
              backtrace
              exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
              exec_on_success("rm -rf output/test_actual/decode_ar004.0888.ls.txt")
              exec_on_success("rm -f output/test_actual/decode_ar004.0888_cat_3eleven.txt")
              exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
            end
          end
        end
      end
    end
  end

  describe "bake" do
    # TODO bake should be tested with decoded files 
    # TODO Bake should allow a shard specifier via -S
    context "with packed file" do
      before :all do
        exec("rm -f output/test_actual/bake_ar003.0698")
        exec("bun bake data/test/ar003.0698 \
                  >output/test_actual/bake_ar003.0698")
      end
      it "should match the expected output" do
        "bake_ar003.0698".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/bake_ar003.0698")
      end
    end
    context "with unpacked file" do
      before :all do
        exec("rm -f output/test_actual/bake_ar003.0698")
        exec("bun bake #{TEST_ARCHIVE}/ar003.0698.bun \
                  >output/test_actual/bake_ar003.0698")
      end
      it "should match the expected output" do
        "bake_ar003.0698".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/bake_ar003.0698")
      end
    end
    context "with unpacked file and --shard" do
      before :all do
        exec("rm -f output/test_actual/bake_ar074.1174_1.3b")
        exec("bun bake --shard 1.3b data/test/ar074.1174.bun \
                  >output/test_actual/bake_ar074.1174_1.3b")
      end
      it "should match the expected output" do
        "bake_ar074.1174_1.3b".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/bake_ar074.1174_1.3b")
      end
    end
    context "with unpacked file and --scrub" do
      before :all do
        exec("rm -f output/test_actual/bake_ar074.1174_1.3b_scrub")
        exec("bun bake --scrub data/test/ar074.1174.bun[1.3b] \
                  >output/test_actual/bake_ar074.1174_1.3b_scrub")
      end
      it "should match the expected output" do
        "bake_ar074.1174_1.3b_scrub".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/bake_ar074.1174_1.3b_scrub")
      end
    end
    context "with decoded file" do
      before :all do
        exec("rm -f output/test_actual/bake_decoded_file.txt")
        exec("bun bake data/test/decoded_file.txt \
                  >output/test_actual/bake_decoded_file.txt")
      end
      it "should match the expected output" do
        "bake_decoded_file.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/bake_decoded_file.txt")
      end
    end
    context "with an existing file" do
      before :all do
        exec("rm -f output/test_actual/bake_decoded_file.txt")
        exec("rm -f output/test_actual/bake_decoded_exists_stderr.txt")
        exec("echo foo >output/test_actual/bake_decoded_file.txt")
        exec("bun bake data/test/decoded_file.txt output/test_actual/bake_decoded_file.txt \
                  2>output/test_actual/bake_decoded_exists_stderr.txt ", allowed: [1])
        @exitstatus = $?.exitstatus
      end
      it "should fail" do
        @exitstatus.should == 1
      end
      it "should not overwrite the existing file" do
        "output/test_actual/bake_decoded_file.txt".should contain_content('foo')
      end
      it "should write the proper messages on STDERR" do
        "bake_decoded_exists_stderr.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/bake_decoded_file.txt")
        exec_on_success("rm -f output/test_actual/bake_decoded_exists_stderr.txt")
      end
    end
    context "with an existing file and --quiet" do
      before :all do
        exec("rm -f output/test_actual/bake_decoded_file.txt")
        exec("rm -f output/test_actual/bake_decoded_exists_stderr.txt")
        exec("echo foo >output/test_actual/bake_decoded_file.txt")
        exec("bun bake --quiet data/test/decoded_file.txt output/test_actual/bake_decoded_file.txt \
                  2>output/test_actual/bake_decoded_exists_stderr.txt ", allowed: [1])
        @exitstatus = $?.exitstatus
      end
      it "should fail" do
        @exitstatus.should == 1
      end
      it "should not overwrite the existing file" do
        "output/test_actual/bake_decoded_file.txt".should contain_content('foo')
      end
      it "should write nothing on STDERR" do
        "bake_decoded_exists_stderr.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/bake_decoded_file.txt")
        exec_on_success("rm -f output/test_actual/bake_decoded_exists_stderr.txt")
      end
    end
    context "with an existing file and --force" do
      before :all do
        exec("rm -f output/test_actual/bake_decoded_file.txt")
        exec("echo foo >output/test_actual/bake_decoded_file.txt")
        exec("bun bake --force data/test/decoded_file.txt output/test_actual/bake_decoded_file.txt")
      end
      it "should match the expected output" do
        "bake_decoded_file.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/bake_decoded_file.txt")
      end
    end
  end

  describe "scrub" do
    [
      {
        :title=>"basic",
        :command=>"scrub data/test/scrub_test.txt"
      },
      {
        :title=>"--tabs",
        :command=>"scrub --tabs 20 data/test/scrub_test.txt"
      },
    ].each do |test|
      exec_test_hash "scrub", test
    end
  end

  describe "dump" do
    include_examples "command", 
                     "dump ar003.0698", 
                     "dump #{TEST_ARCHIVE}/ar003.0698.bun", 
                     "dump_ar003.0698"
    include_examples "command", 
                     "dump -s ar003.0698", 
                     "dump -s #{TEST_ARCHIVE}/ar003.0698.bun",
                     "dump_s_ar003.0698"
    include_examples "command", 
                     "dump ar004.0888", 
                     "dump #{TEST_ARCHIVE}/ar004.0888.bun", 
                     "dump_ar004.0888"
    include_examples "command", 
                     "dump -f ar004.0888", 
                     "dump -f #{TEST_ARCHIVE}/ar004.0888.bun",
                     "dump_f_ar004.0888"
    include_examples "command from STDIN", 
                     "dump ar003.0698", 
                     "dump - ", 
                     "#{TEST_ARCHIVE}/ar003.0698.bun", 
                     "dump_stdin_ar003.0698"
    after :all do
      backtrace
    end
  end

  describe "freezer" do
    context "ls" do
      include_examples "command", 
                       "freezer ls ar004.0888", 
                       "freezer ls #{TEST_ARCHIVE}/ar004.0888.bun",
                       "freezer_ls_ar004.0888"
      include_examples "command", 
                       "freezer ls -l ar004.0888", 
                       "freezer ls -l #{TEST_ARCHIVE}/ar004.0888.bun", 
                       "freezer_ls_l_ar004.0888"
      include_examples "command from STDIN", 
                       "freezer ls ar004.0888", 
                       "freezer ls -",
                       "#{TEST_ARCHIVE}/ar004.0888.bun",
                       "freezer_ls_stdin_ar004.0888"
      after :all do
        backtrace
      end
    end
    context "dump" do
      include_examples "command", 
                       "freezer dump ar004.0888 +0", 
                       "freezer dump #{TEST_ARCHIVE}/ar004.0888.bun +0", 
                       "freezer_dump_ar004.0888_0"
      include_examples "command", 
                       "freezer dump -s ar004.0888 +0", 
                       "freezer dump -s #{TEST_ARCHIVE}/ar004.0888.bun +0", 
                       "freezer_dump_s_ar004.0888_0"
      include_examples "command from STDIN", 
                       "freezer dump ar004.0888 +0", 
                       "freezer dump - +0",
                       "#{TEST_ARCHIVE}/ar004.0888.bun", 
                       "freezer_dump_stdin_ar004.0888_0"
      after :all do
        backtrace
      end
    end
  end

  describe "catalog" do
    before :all do
      exec("rm -rf data/test/archive/catalog_source")
      exec("cp -r data/test/archive/catalog_source_init data/test/archive/catalog_source")
      exec("bun archive catalog data/test/archive/catalog_source --catalog data/test/catalog.txt \
                2>output/test_actual/archive_catalog_stderr.txt >output/test_actual/archive_catalog_stdout.txt")
    end
    it "should write nothing on stdout" do
      'output/test_actual/archive_catalog_stdout.txt'.should be_an_empty_file
    end
    it "should write file decoding messages on stderr" do
      "archive_catalog_stderr.txt".should match_expected_output
    end
    it "should not add or remove any files in the archive" do
      exec('find data/test/archive/catalog_source -print >output/test_actual/archive_catalog_files.txt')
      'archive_catalog_files.txt'.should match_expected_output
    end
    %w{ar003.0698.bun  ar003.0701.bun  ar082.0605.bun  ar083.0698.bun}.each do |file|
      context file do
        before :all do
          @catalog_describe_basename = "catalog_describe_#{file}"
          @catalog_describe_output_file = "output/test_actual/#{@catalog_describe_basename}"
          exec("rm -rf #{@catalog_describe_output_file}")
          exec("bun describe data/test/archive/catalog_source/#{file} >#{@catalog_describe_output_file}")
        end
        it "should change the catalog dates and incomplete_file fields" do 
          @catalog_describe_basename.should match_expected_output_except_for(DESCRIBE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -rf #{@catalog_describe_output_file}")
        end
      end
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/catalog_source")
      exec_on_success("rm -f output/test_actual/archive_catalog_stderr.txt")
      exec_on_success("rm -f output/test_actual/archive_catalog_stdout.txt")
      exec_on_success("rm -f output/test_actual/archive_catalog_files.txt")
    end
  end

  describe "archive decode" do
    before :all do
      exec("rm -rf data/test/archive/decode_source")
      exec("rm -rf data/test/archive/decode_archive")
      exec("cp -r data/test/archive/decode_source_init data/test/archive/decode_source")
      exec("bun archive decode data/test/archive/decode_source data/test/archive/decode_archive \
                2>output/test_actual/archive_decode_stderr.txt >output/test_actual/archive_decode_stdout.txt")
    end
    it "should create a tapes directory" do
      file_should_exist "data/test/archive/decode_archive"
    end
    it "should write nothing on stdout" do
      'output/test_actual/archive_decode_stdout.txt'.should be_an_empty_file
    end
    it "should write file decoding messages on stderr" do
      "archive_decode_stderr.txt".should match_expected_output
    end
    it "should create the appropriate files" do
      exec('find data/test/archive/decode_archive -print >output/test_actual/archive_decode_files.txt')
      'archive_decode_files.txt'.should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/decode_source")
      exec_on_success("rm -rf data/test/archive/decode_archive")
      exec_on_success("rm -f output/test_actual/archive_decode_stderr.txt")
      exec_on_success("rm -f output/test_actual/archive_decode_stdout.txt")
      exec_on_success("rm -f output/test_actual/archive_decode_files.txt")
    end
  end

  describe "mixed archive" do
    context "unpack" do
      before :all do
        exec("rm -rf data/test/archive/mixed_formats")
        exec("rm -rf output/test_actual/mixed_formats_unpack")
        exec("rm -f output/test_actual/mixed_formats_archive_unpack.txt")
        exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
        exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
        exec("bun archive unpack data/test/archive/mixed_formats output/test_actual/mixed_formats_unpack 2>/dev/null \
                  >/dev/null")
      end
      it "should create the proper files" do
        exec "find output/test_actual/mixed_formats_unpack -print >output/test_actual/mixed_formats_archive_unpack.txt"
        'mixed_formats_archive_unpack.txt'.should match_expected_output
      end
      it "should write the proper content" do
        "mixed_formats_unpack/ar003.0698.bun".should match_expected_output_except_for(UNPACK_PATTERNS)
        "mixed_formats_unpack/ar003.0701.bun".should match_expected_output_except_for(UNPACK_PATTERNS)
        "mixed_formats_unpack/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt".should \
            match_expected_output
        "mixed_formats_unpack/fass/script/tape.ar004.0642_19770224.txt".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/mixed_formats")
        exec_on_success("rm -rf output/test_actual/mixed_formats_unpack")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_unpack.txt")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
      end
    end
    context "catalog" do
      before :all do
        exec("rm -rf data/test/archive/mixed_formats")
        exec("rm -rf output/test_actual/mixed_formats_catalog")
        exec("rm -f output/test_actual/mixed_formats_archive_catalog.txt")
        exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
        exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
        exec("bun archive catalog --catalog data/test/fass-index.txt \
                  data/test/archive/mixed_formats \
                  output/test_actual/mixed_formats_catalog \
                  2>/dev/null \
                  >/dev/null")
      end
      it "should create the proper files" do
        exec "find output/test_actual/mixed_formats_catalog -print >output/test_actual/mixed_formats_archive_catalog.txt"
        'mixed_formats_archive_catalog.txt'.should match_expected_output
      end
      it "should write the proper content" do
        "mixed_formats_catalog/ar003.0698.bun".should match_expected_output_except_for(UNPACK_PATTERNS)
        "mixed_formats_catalog/ar003.0701.bun".should match_expected_output_except_for(UNPACK_PATTERNS)
        "mixed_formats_catalog/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt".should \
            match_expected_output
        "mixed_formats_catalog/fass/script/tape.ar004.0642_19770224.txt".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/mixed_formats")
        exec_on_success("rm -rf output/test_actual/mixed_formats_catalog")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_catalog.txt")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
      end
    end
    context "decode" do
      before :all do
        exec("rm -rf data/test/archive/mixed_formats")
        exec("rm -rf output/test_actual/mixed_formats_decode")
        exec("rm -f output/test_actual/mixed_formats_archive_decode.txt")
        exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
        exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
        exec("bun archive decode data/test/archive/mixed_formats output/test_actual/mixed_formats_decode 2>/dev/null \
                  >/dev/null")
      end
      it "should create the proper files" do
        exec "find output/test_actual/mixed_formats_decode -print >output/test_actual/mixed_formats_archive_decode.txt"
        'mixed_formats_archive_decode.txt'.should match_expected_output
      end
      it "should write the proper content" do
        "mixed_formats_decode/fass/idallen/vector/tape.ar003.0698.txt".should match_expected_output_except_for(DECODE_PATTERNS)
        "mixed_formats_decode/fass/idallen/huffhart/tape.ar003.0701_19761122.txt".should match_expected_output_except_for(DECODE_PATTERNS)
        "mixed_formats_decode/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt".should \
            match_expected_output
        "mixed_formats_decode/fass/script/tape.ar004.0642_19770224.txt".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/mixed_formats")
        exec_on_success("rm -rf output/test_actual/mixed_formats_decode")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_decode.txt")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
      end
    end
    context "bake" do
      before :all do
        exec("rm -rf data/test/archive/mixed_formats")
        exec("rm -rf output/test_actual/mixed_formats_bake")
        exec("rm -f output/test_actual/mixed_formats_archive_bake.txt")
        exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
        exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
        exec("bun archive bake data/test/archive/mixed_formats output/test_actual/mixed_formats_bake 2>/dev/null \
                  >/dev/null")
      end
      it "should create the proper files" do
        exec "find output/test_actual/mixed_formats_bake -print >output/test_actual/mixed_formats_archive_bake.txt"
        'mixed_formats_archive_bake.txt'.should match_expected_output
      end
      it "should write the proper content" do
        "mixed_formats_bake/ar003.0698".should match_expected_output
        "mixed_formats_bake/ar003.0701.bun".should match_expected_output
        "mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt".should \
            match_expected_output
        "mixed_formats_bake/fass/script/tape.ar004.0642_19770224.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/mixed_formats")
        exec_on_success("rm -rf output/test_actual/mixed_formats_bake")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_bake.txt")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
      end
    end
    context "describe" do
      context "packed file (ar003.0698)" do
        before :all do
          exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
          exec("rm -rf output/test_actual/mixed_formats_describe_ar003.0698")
          exec("bun describe data/test/archive/mixed_formats/ar003.0698 >output/test_actual/mixed_formats_describe_ar003.0698")
        end
        it "should match the expected output" do
          "mixed_formats_describe_ar003.0698".should match_expected_output
        end
        after :all do
          backtrace
          exec_on_success("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
          exec_on_success("rm -rf output/test_actual/mixed_formats_describe_ar003.0698")
        end      
      end
      context "unpacked file (ar003.0701.bun)" do
        before :all do
          exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
          exec("rm -rf output/test_actual/mixed_formats_describe_ar003.0701.bun")
          exec("bun describe data/test/archive/mixed_formats/ar003.0701.bun >output/test_actual/mixed_formats_describe_ar003.0701.bun")
        end
        it "should match the expected output" do
          "mixed_formats_describe_ar003.0701.bun".should match_expected_output_except_for(DESCRIBE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
          exec_on_success("rm -rf output/test_actual/mixed_formats_describe_ar003.0701.bun")
        end      
      end
      context "decoded file (fass/script/tape.ar004.0642_19770224.txt)" do
        before :all do
          exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
          exec("rm -rf output/test_actual/mixed_formats_describe_fass_script_tape.ar004.0642_19770224.txt")
          exec("bun describe data/test/archive/mixed_formats/fass/script/tape.ar004.0642_19770224.txt >output/test_actual/mixed_formats_describe_fass_script_tape.ar004.0642_19770224.txt")
        end
        it "should match the expected output" do
          "mixed_formats_describe_fass_script_tape.ar004.0642_19770224.txt".should match_expected_output_except_for(DESCRIBE_WITH_DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
          exec_on_success("rm -rf output/test_actual/mixed_formats_describe_fass_script_tape.ar004.0642_19770224.txt")
        end      
      end
      context "baked file (fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt)" do
        before :all do
          exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
          exec("rm -rf output/test_actual/mixed_formats_describe_clean_fass_1986_script_script.f_19860213_1-1_tape.ar120.0740_19860213_134229.txt")
          exec("bun describe data/test/archive/mixed_formats/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt >output/test_actual/mixed_formats_describe_fass_1986_script_script.f_19860213_1-1_tape.ar120.0740_19860213_134229.txt")
        end
        it "should match the expected output" do
          "mixed_formats_describe_fass_1986_script_script.f_19860213_1-1_tape.ar120.0740_19860213_134229.txt".should match_expected_output
        end
        after :all do
          backtrace
          exec_on_success("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
          exec_on_success("rm -rf output/test_actual/mixed_formats_describe_clean_fass_1986_script_script.f_19860213_1-1_tape.ar120.0740_19860213_134229.txt")
        end      
      end
    end
  end

  describe "compress" do
    context "to a new directory" do
      before :all do
        exec("rm -rf data/test/archive/compress")
        exec("rm -rf output/test_actual/compress")
        exec("rm -rf output/test_actual/compress_files.txt")
        exec("rm -rf output/test_actual/compress_files_before.txt")
        exec("rm -rf output/test_actual/compress_stdout.txt")
        exec("rm -rf output/test_actual/compress_stderr.txt")
        exec("cp -r data/test/archive/compress_init data/test/archive/compress")
        exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
        exec("bun compress data/test/archive/compress output/test_actual/compress \
                  2>output/test_actual/compress_stderr.txt >output/test_actual/compress_stdout.txt")
        exec("find output/test_actual/compress -print >output/test_actual/compress_files.txt")
      end
      it "should create the proper files" do
        "compress_files.txt".should match_expected_output
      end
      it "should leave the original directory alone" do
        "compress_files_before.txt".should match_expected_output
      end
      it "should write the proper messages on STDERR" do
        "compress_stderr.txt".should match_expected_output
      end
      it "should write nothing on STDOUT" do
        "output/test_actual/compress_stdout.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/compress")
        exec_on_success("rm -rf output/test_actual/compress")
        exec_on_success("rm -rf output/test_actual/compress_files.txt")
        exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
        exec_on_success("rm -rf output/test_actual/compress_stdout.txt")
        exec_on_success("rm -rf output/test_actual/compress_stderr.txt")
      end
    end
    context "to a new directory --quiet" do
      before :all do
        exec("rm -rf data/test/archive/compress")
        exec("rm -rf output/test_actual/compress")
        exec("rm -rf output/test_actual/compress_files.txt")
        exec("rm -rf output/test_actual/compress_files_before.txt")
        exec("rm -rf output/test_actual/compress_stdout.txt")
        exec("rm -rf output/test_actual/compress_stderr.txt")
        exec("cp -r data/test/archive/compress_init data/test/archive/compress")
        exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
        exec("bun compress data/test/archive/compress output/test_actual/compress \
                  2>output/test_actual/compress_stderr.txt >output/test_actual/compress_stdout.txt")
        exec("find output/test_actual/compress -print >output/test_actual/compress_files.txt")
      end
      it "should create the proper files" do
        "compress_files.txt".should match_expected_output
      end
      it "should leave the original directory alone" do
        "compress_files_before.txt".should match_expected_output
      end
      it "should write nothing on STDERR" do
        "compress_stderr.txt".should be_an_empty_file
      end
      it "should write nothing on STDOUT" do
        "output/test_actual/compress_stdout.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/compress")
        exec_on_success("rm -rf output/test_actual/compress")
        exec_on_success("rm -rf output/test_actual/compress_files.txt")
        exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
        exec_on_success("rm -rf output/test_actual/compress_stdout.txt")
        exec_on_success("rm -rf output/test_actual/compress_stderr.txt")
      end
    end
    context "to an existing directory" do
      before :all do
        exec("rm -rf data/test/archive/compress")
        exec("rm -rf output/test_actual/compress")
        exec("rm -rf output/test_actual/compress_files_existing.txt")
        exec("rm -rf output/test_actual/compress_stdout_existing.txt")
        exec("rm -rf output/test_actual/compress_stderr_existing.txt")
        exec("cp -r data/test/archive/compress_init data/test/archive/compress")
        exec("mkdir output/test_actual/compress")
        exec("bun compress data/test/archive/compress output/test_actual/compress \
                  2>output/test_actual/compress_stderr_existing.txt \
                  >output/test_actual/compress_stdout_existing.txt",
                  allowed: [1])
        @exitstatus = $?.exitstatus
        exec("find output/test_actual/compress -print >output/test_actual/compress_files_existing.txt")
      end
      it "should fail" do
        @exitstatus.should == 1
      end
      it "should not create any files" do
        "compress_files_existing.txt".should match_expected_output
      end
      it "should write the proper messages on STDERR" do
        "compress_stderr_existing.txt".should match_expected_output
      end
      it "should write nothing on STDOUT" do
        "output/test_actual/compress_stdout_existing.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/compress")
        exec_on_success("rm -rf output/test_actual/compress")
        exec_on_success("rm -rf output/test_actual/compress_files.txt")
        exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
        exec_on_success("rm -rf output/test_actual/compress_stdout.txt")
        exec_on_success("rm -rf output/test_actual/compress_stderr.txt")
      end
    end
    context "to an existing directory with --force" do
      before :all do
        exec("rm -rf data/test/archive/compress")
        exec("rm -rf output/test_actual/compress")
        exec("rm -rf output/test_actual/compress_files.txt")
        exec("rm -rf output/test_actual/compress_files_before.txt")
        exec("rm -rf output/test_actual/compress_stdout.txt")
        exec("rm -rf output/test_actual/compress_stderr.txt")
        exec("mkdir output/test_actual/compress")
        exec("cp -r data/test/archive/compress_init data/test/archive/compress")
        exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
        exec("bun compress --force data/test/archive/compress output/test_actual/compress \
                  2>output/test_actual/compress_stderr.txt >output/test_actual/compress_stdout.txt")
        exec("find output/test_actual/compress -print >output/test_actual/compress_files.txt")
      end
      it "should create the proper files" do
        "compress_files.txt".should match_expected_output
      end
      it "should leave the original directory alone" do
        "compress_files_before.txt".should match_expected_output
      end
      it "should write the proper messages on STDERR" do
        "compress_stderr.txt".should match_expected_output
      end
      it "should write nothing on STDOUT" do
        "output/test_actual/compress_stdout.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/compress")
        exec_on_success("rm -rf output/test_actual/compress")
        exec_on_success("rm -rf output/test_actual/compress_files.txt")
        exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
        exec_on_success("rm -rf output/test_actual/compress_stdout.txt")
        exec_on_success("rm -rf output/test_actual/compress_stderr.txt")
      end
    end
    context "to the same directory" do
      before :all do
        exec("rm -rf data/test/archive/compress")
        exec("rm -rf output/test_actual/compress_files_inplace.txt")
        exec("rm -rf output/test_actual/compress_files_before.txt")
        exec("rm -rf output/test_actual/compress_stdout_inplace.txt")
        exec("rm -rf output/test_actual/compress_stderr_inplace.txt")
        exec("cp -r data/test/archive/compress_init data/test/archive/compress")
        exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
        exec("bun compress data/test/archive/compress \
                  2>output/test_actual/compress_stderr_inplace.txt >output/test_actual/compress_stdout_inplace.txt")
        exec("find data/test/archive/compress -print >output/test_actual/compress_files_inplace.txt")
      end
      it "should create the proper files" do
        "compress_files_inplace.txt".should match_expected_output
      end
      it "should leave the original directory alone" do
        "compress_files_before.txt".should match_expected_output
      end
      it "should write the proper messages on STDERR" do
        "compress_stderr_inplace.txt".should match_expected_output
      end
      it "should write nothing on STDOUT" do
        "output/test_actual/compress_stdout_inplace.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/compress")
        exec_on_success("rm -rf output/test_actual/compress_files_inplace.txt")
        exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
        exec_on_success("rm -rf output/test_actual/compress_stdout_inplace.txt")
        exec_on_success("rm -rf output/test_actual/compress_stderr_inplace.txt")
      end
    end
  end
  describe "same" do
    before :all do
      exec("rm -rf output/test_actual/same_stdout.txt")
      exec("bun same digest data/test/archive/same >output/test_actual/same_stdout.txt")
    end
    it "should produce the proper output" do
      "same_stdout.txt".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -rf output/test_actual/same_stdout.txt")
    end
  end

  describe "test build" do
    context "without --quiet" do
      before :all do
        exec("rm -rf output/test_actual/test_build_files.txt")
        exec("rm -rf output/test_actual/test_build_stdout.txt")
        exec("rm -rf output/test_actual/test_build_stderr.txt")
        exec("bun test build \
                  2>output/test_actual/test_build_stderr.txt >output/test_actual/test_build_stdout.txt")
        exec("find data/test -print >output/test_actual/test_build_files.txt")
      end
      it "should create the proper files" do
        "test_build_files.txt".should match_expected_output
      end
      it "should write the proper messages on STDERR" do
        "test_build_stderr.txt".should match_expected_output
      end
      it "should write nothing on STDOUT" do
        "output/test_actual/test_build_stdout.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -rf output/test_actual/test_build_files.txt")
        exec_on_success("rm -rf output/test_actual/test_build_stdout.txt")
        exec_on_success("rm -rf output/test_actual/test_build_stderr.txt")
      end
    end
    context "without --quiet" do
      before :all do
        exec("rm -rf output/test_actual/test_build_files.txt")
        exec("rm -rf output/test_actual/test_build_stdout.txt")
        exec("rm -rf output/test_actual/test_build_stderr.txt")
        exec("bun test build --quiet \
                  2>output/test_actual/test_build_stderr.txt >output/test_actual/test_build_stdout.txt")
        exec("find data/test -print >output/test_actual/test_build_files.txt")
      end
      it "should create the proper files" do
        "test_build_files.txt".should match_expected_output
      end
      it "should write nothing on STDERR" do
        "test_build_stderr.txt".should be_an_empty_file
      end
      it "should write nothing on STDOUT" do
        "output/test_actual/test_build_stdout.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -rf output/test_actual/test_build_files.txt")
        exec_on_success("rm -rf output/test_actual/test_build_stdout.txt")
        exec_on_success("rm -rf output/test_actual/test_build_stderr.txt")
      end
    end
  end
end