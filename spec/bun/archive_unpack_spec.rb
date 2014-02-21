#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "archive unpack" do
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
  context "to directory with existing files" do
    context "without --force" do
      before :all do
        exec("rm -rf data/test/archive/general_test_packed_unpacked")
        exec("rm -f output/test_actual/archive_unpack_existing_directory_files.txt")
        exec("rm -f output/test_actual/archive_unpack_existing_directory_stdout.txt")
        exec("rm -f output/test_actual/archive_unpack_existing_directory_stderr.txt")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("mkdir data/test/archive/general_test_packed_unpacked")
        exec("echo foo > data/test/archive/general_test_packed_unpacked/foo_file")
        exec("echo bar > data/test/archive/general_test_packed_unpacked/ar004.0888.bun")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun archive unpack data/test/archive/general_test_packed \
                data/test/archive/general_test_packed_unpacked \
                2>output/test_actual/archive_unpack_existing_directory_stderr.txt \
                >output/test_actual/archive_unpack_existing_directory_stdout.txt")
        exec("find data/test/archive/general_test_packed_unpacked -print \
                >output/test_actual/archive_unpack_existing_directory_files.txt")
      end
      it "should write nothing on stdout" do
        'output/test_actual/archive_unpack_existing_directory_stdout.txt'.should be_an_empty_file
      end
      it "should write file decoding messages on stderr" do
        "archive_unpack_existing_directory_stderr.txt".should match_expected_output
      end
      # Leaving all the pre-existing files
      it "should create the appropriate files" do
        exec('find data/test/archive/general_test_packed_unpacked -print \
                  >output/test_actual/archive_unpack_existing_directory_files.txt')
        "archive_unpack_existing_directory_files.txt".should match_expected_output
      end
      it "should not change the content of existing files" do
        "data/test/archive/general_test_packed_unpacked/ar004.0888.bun".should contain_content('bar')
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
        exec_on_success("rm -f output/test_actual/archive_unpack_existing_directory_files.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_existing_directory_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_existing_directory_stdout.txt")
      end
    end
    context "with --force" do
      before :all do
        exec("rm -rf data/test/archive/general_test_packed_unpacked")
        exec("rm -f output/test_actual/archive_unpack_existing_directory_force_files.txt")
        exec("rm -f output/test_actual/archive_unpack_existing_directory_force_stdout.txt")
        exec("rm -f output/test_actual/archive_unpack_existing_directory_force_stderr.txt")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("mkdir data/test/archive/general_test_packed_unpacked")
        exec("echo foo > data/test/archive/general_test_packed_unpacked/foo_file")
        exec("echo bar > data/test/archive/general_test_packed_unpacked/ar004.0888")
        exec("bun archive unpack --force data/test/archive/general_test_packed \
                data/test/archive/general_test_packed_unpacked \
                2>output/test_actual/archive_unpack_existing_directory_force_stderr.txt \
                >output/test_actual/archive_unpack_existing_directory_force_stdout.txt")
      end
      it "should write nothing on stdout" do
        'output/test_actual/archive_unpack_existing_directory_force_stdout.txt'.should be_an_empty_file
      end
      it "should write file decoding messages on stderr" do
        "archive_unpack_existing_directory_force_stderr.txt".should match_expected_output
      end
      # Including wiping out all the pre-existing files
      it "should create the appropriate files" do
        exec('find data/test/archive/general_test_packed_unpacked -print \
                  >output/test_actual/archive_unpack_existing_directory_force_files.txt')
        "archive_unpack_existing_directory_force_files.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
        exec_on_success("rm -f output/test_actual/archive_unpack_existing_directory_force_files.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_existing_directory_force_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_existing_directory_force_stdout.txt")
      end
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
  context "with bad files" do
    context "without --fix" do
      before :all do
        exec("rm -rf data/test/archive/general_test_packed_unpacked_fix")
        exec("rm -f output/test_actual/archive_unpack_fix_fail_files.txt")
        exec("rm -f output/test_actual/archive_unpack_fix_fail_stdout.txt")
        exec("rm -f output/test_actual/archive_unpack_fix_fail_stderr.txt")
        exec("rm -rf data/test/archive/packed_with_bad_files")
        exec("cp -r data/test/archive/packed_with_bad_files_init data/test/archive/packed_with_bad_files")
        exec("bun archive unpack data/test/archive/packed_with_bad_files \
                data/test/archive/general_test_packed_unpacked_fix \
                2>output/test_actual/archive_unpack_fix_fail_stderr.txt \
                >output/test_actual/archive_unpack_fix_fail_stdout.txt", allowed: [1])
        @exitstatus = $?.exitstatus
      end
      it "should fail" do
        @exitstatus.should == 1
      end
      it "should create a new directory" do
        file_should_exist "data/test/archive/general_test_packed_unpacked_fix"
      end
      it "should write nothing on stdout" do
        'output/test_actual/archive_unpack_fix_fail_stdout.txt'.should be_an_empty_file
      end
      it "should write messages on stderr" do
        "archive_unpack_fix_fail_stderr.txt".should match_expected_output
      end
      it "should create the appropriate files" do
        exec('find data/test/archive/general_test_packed_unpacked_fix -print \
                  >output/test_actual/archive_unpack_fix_fail_files.txt')
        "archive_unpack_fix_fail_files.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked_fix")
        exec_on_success("rm -f output/test_actual/archive_unpack_fix_fail_files.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_fix_fail_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_fix_fail_stdout.txt")
        exec_on_success("rm -rf data/test/archive/packed_with_bad_files")
      end
    end
    context "with --fix" do
      before :all do
        exec("rm -rf data/test/archive/general_test_packed_unpacked_fix")
        exec("rm -f output/test_actual/archive_unpack_fix_files.txt")
        exec("rm -f output/test_actual/archive_unpack_fix_stdout.txt")
        exec("rm -f output/test_actual/archive_unpack_fix_stderr.txt")
        exec("rm -rf data/test/archive/packed_with_bad_files")
        exec("cp -r data/test/archive/packed_with_bad_files_init data/test/archive/packed_with_bad_files")
        exec("bun archive unpack --fix data/test/archive/packed_with_bad_files \
                data/test/archive/general_test_packed_unpacked_fix \
                2>output/test_actual/archive_unpack_fix_stderr.txt \
                >output/test_actual/archive_unpack_fix_stdout.txt")
      end
      it "should create a new directory" do
        file_should_exist "data/test/archive/general_test_packed_unpacked_fix"
      end
      it "should write nothing on stdout" do
        'output/test_actual/archive_unpack_fix_stdout.txt'.should be_an_empty_file
      end
      it "should write file decoding messages on stderr" do
        "archive_unpack_fix_stderr.txt".should match_expected_output
      end
      it "should create the appropriate files" do
        exec('find data/test/archive/general_test_packed_unpacked_fix -print \
                  >output/test_actual/archive_unpack_fix_files.txt')
        "archive_unpack_fix_files.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked_fix")
        exec_on_success("rm -f output/test_actual/archive_unpack_fix_files.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_fix_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_unpack_fix_stdout.txt")
        exec_on_success("rm -rf data/test/archive/packed_with_bad_files")
      end
    end
  end
  context "mixed archive" do
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
      "mixed_formats_unpack/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.bun".should \
          match_expected_output
      "mixed_formats_unpack/fass/script/tape.ar004.0642_19770224.bun".should match_expected_output_except_for(DECODE_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/mixed_formats")
      exec_on_success("rm -rf output/test_actual/mixed_formats_unpack")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_unpack.txt")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
    end
  end
end
