#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "archive bake" do
  context "normal" do
    before :all do
      exec("rm -rf data/test/archive/mixed_formats")
      exec("rm -rf output/test_actual/mixed_formats_bake")
      exec("rm -f output/test_actual/mixed_formats_archive_bake.txt")
      exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
      exec("rm -f output/test_actual/archive_bake_stdout.txt")
      exec("rm -f output/test_actual/archive_bake_stderr.txt")
      exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec("bun archive bake data/test/archive/mixed_formats \
                output/test_actual/mixed_formats_bake \
                >output/test_actual/archive_bake_stdout.txt \
                2>output/test_actual/archive_bake_stderr.txt")
    end
    it "should create the proper files" do
      exec "find output/test_actual/mixed_formats_bake -print >output/test_actual/mixed_formats_archive_bake.txt"
      'mixed_formats_archive_bake.txt'.should match_expected_output
    end
    it "should write the proper content" do
      "mixed_formats_bake/ar003.0698".should match_expected_output
      "mixed_formats_bake/ar003.0701.bun".should match_expected_output
      "mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229".should \
          match_expected_output
      "mixed_formats_bake/fass/script/tape.ar004.0642_19770224".should match_expected_output
    end
    it "should write nothing on STDOUT" do 
      "output/test_actual/archive_bake_stdout.txt".should be_an_empty_file
    end
    it "should write messages on STDERR" do 
      "archive_bake_stderr.txt".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/mixed_formats")
      exec_on_success("rm -rf output/test_actual/mixed_formats_bake")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_bake.txt")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
      exec_on_success("rm -f output/test_actual/archive_bake_stdout.txt")
      exec_on_success("rm -f output/test_actual/archive_bake_stderr.txt")
    end
  end

  context "with --quiet" do
    before :all do
      exec("rm -rf data/test/archive/mixed_formats")
      exec("rm -rf output/test_actual/mixed_formats_bake")
      exec("rm -f output/test_actual/mixed_formats_archive_bake.txt")
      exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
      exec("rm -f output/test_actual/archive_bake_quiet_stdout.txt")
      exec("rm -f output/test_actual/archive_bake_quiet_stderr.txt")
      exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec("bun archive bake --quiet data/test/archive/mixed_formats \
                output/test_actual/mixed_formats_bake \
                >output/test_actual/archive_bake_quiet_stdout.txt \
                2>output/test_actual/archive_bake_quiet_stderr.txt")
    end
    it "should create the proper files" do
      exec "find output/test_actual/mixed_formats_bake -print >output/test_actual/mixed_formats_archive_bake.txt"
      'mixed_formats_archive_bake.txt'.should match_expected_output
    end
    it "should write the proper content" do
      "mixed_formats_bake/ar003.0698".should match_expected_output
      "mixed_formats_bake/ar003.0701.bun".should match_expected_output
      "mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229".should \
          match_expected_output
      "mixed_formats_bake/fass/script/tape.ar004.0642_19770224".should match_expected_output
    end
    it "should write nothing on STDOUT" do 
      "output/test_actual/archive_bake_quiet_stdout.txt".should be_an_empty_file
    end
    it "should write nothing on STDERR" do 
      "output/test_actual/archive_bake_quiet_stderr.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/mixed_formats")
      exec_on_success("rm -rf output/test_actual/mixed_formats_bake")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_bake.txt")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
      exec_on_success("rm -f output/test_actual/archive_bake_quiet_stdout.txt")
      exec_on_success("rm -f output/test_actual/archive_bake_quiet_stderr.txt")
    end
  end

  context "to an existing directory" do
    context "with --force" do
      before :all do
        exec("rm -rf data/test/archive/mixed_formats")
        exec("rm -rf output/test_actual/mixed_formats_bake")
        exec("rm -f output/test_actual/mixed_formats_archive_bake.txt")
        exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
        exec("rm -f output/test_actual/archive_bake_stdout.txt")
        exec("rm -f output/test_actual/archive_bake_stderr.txt")
        exec("mkdir output/test_actual/mixed_formats_bake")
        exec("mkdir -p output/test_actual/mixed_formats_bake/fass/1986/script/script.f_19860213/1-1")
        exec("echo foo >output/test_actual/mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229")
        exec("echo bar >output/test_actual/mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/xyzzy")
        exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
        exec("bun archive bake --force data/test/archive/mixed_formats \
                  output/test_actual/mixed_formats_bake \
                  >output/test_actual/archive_bake_stdout.txt \
                  2>output/test_actual/archive_bake_stderr.txt")
      end
      it "should create the proper files" do
        exec "find output/test_actual/mixed_formats_bake -print >output/test_actual/mixed_formats_archive_bake.txt"
        'mixed_formats_archive_bake.txt'.should match_expected_output
      end
      it "should write the proper content" do
        "mixed_formats_bake/ar003.0698".should match_expected_output
        "mixed_formats_bake/ar003.0701.bun".should match_expected_output
        "mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229".should \
            match_expected_output
        "mixed_formats_bake/fass/script/tape.ar004.0642_19770224".should match_expected_output
      end
      it "should write nothing on STDOUT" do 
        "output/test_actual/archive_bake_stdout.txt".should be_an_empty_file
      end
      it "should write messages on STDERR" do 
        "archive_bake_stderr.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/mixed_formats")
        exec_on_success("rm -rf output/test_actual/mixed_formats_bake")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_bake.txt")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
        exec_on_success("rm -f output/test_actual/archive_bake_stdout.txt")
        exec_on_success("rm -f output/test_actual/archive_bake_stderr.txt")
      end
    end

    context "without --force" do
      before :all do
        exec("rm -rf data/test/archive/mixed_formats")
        exec("rm -rf output/test_actual/mixed_formats_bake")
        exec("rm -f output/test_actual/mixed_formats_archive_bake_existing_no_force.txt")
        exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
        exec("rm -f output/test_actual/archive_bake_existing_no_force_stdout.txt")
        exec("rm -f output/test_actual/archive_bake_existing_no_force_stderr.txt")
        exec("mkdir output/test_actual/mixed_formats_bake")
        exec("mkdir -p output/test_actual/mixed_formats_bake/fass/1986/script/script.f_19860213/1-1")
        exec("echo foo >output/test_actual/mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229")
        exec("echo bar >output/test_actual/mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/xyzzy")
        exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
        exec("bun archive bake data/test/archive/mixed_formats \
                  output/test_actual/mixed_formats_bake \
                  >output/test_actual/archive_bake_existing_no_force_stdout.txt \
                  2>output/test_actual/archive_bake_existing_no_force_stderr.txt")
      end
      it "should create the proper files" do
        exec "find output/test_actual/mixed_formats_bake -print >output/test_actual/mixed_formats_archive_bake_existing_no_force.txt"
        'mixed_formats_archive_bake_existing_no_force.txt'.should match_expected_output
      end
      it "should write the proper content to the non-conflicted files" do
        "mixed_formats_bake/ar003.0698".should match_expected_output
        "mixed_formats_bake/ar003.0701.bun".should match_expected_output
        "mixed_formats_bake/fass/script/tape.ar004.0642_19770224".should match_expected_output
      end
      it "should not overwrite existing files" do
        "output/test_actual/mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229".should contain_content('foo')
        "output/test_actual/mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/xyzzy".should contain_content('bar')
      end
      it "should write nothing on STDOUT" do 
        "output/test_actual/archive_bake_existing_no_force_stdout.txt".should be_an_empty_file
      end
      it "should write messages on STDERR" do 
        "archive_bake_existing_no_force_stderr.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/mixed_formats")
        exec_on_success("rm -rf output/test_actual/mixed_formats_bake")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_bake_existing_no_force.txt")
        exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
        exec_on_success("rm -f output/test_actual/archive_bake_existing_no_force_stdout.txt")
        exec_on_success("rm -f output/test_actual/archive_bake_existing_no_force_stderr.txt")
      end
    end
  end
end
