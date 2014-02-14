#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

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
      exec("bun compress data/test/archive/compress output/test_actual/compress \
                2>output/test_actual/compress_stderr.txt >output/test_actual/compress_stdout.txt")
      exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
      exec("find output/test_actual/compress -print >output/test_actual/compress_files.txt")
    end
    it "should leave the original directory alone" do
      "compress_files_before.txt".should match_expected_output
    end
    it "should create the proper files" do
      "compress_files.txt".should match_expected_output
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
      exec("bun compress data/test/archive/compress output/test_actual/compress \
                2>output/test_actual/compress_stderr.txt >output/test_actual/compress_stdout.txt")
      exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
      exec("find output/test_actual/compress -print >output/test_actual/compress_files.txt")
    end
    it "should leave the original directory alone" do
      "compress_files_before.txt".should match_expected_output
    end
    it "should create the proper files" do
      "compress_files.txt".should match_expected_output
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
  context "to a new directory --delete" do
    before :all do
      exec("rm -rf data/test/archive/compress")
      exec("rm -rf output/test_actual/compress")
      exec("rm -rf output/test_actual/compress_delete_files.txt")
      exec("rm -rf output/test_actual/compress_files_before.txt")
      exec("rm -rf output/test_actual/compress_delete_stdout.txt")
      exec("rm -rf output/test_actual/compress_delete_stderr.txt")
      exec("cp -r data/test/archive/compress_init data/test/archive/compress")
      exec("bun compress --delete data/test/archive/compress output/test_actual/compress \
                2>output/test_actual/compress_delete_stderr.txt \
                >output/test_actual/compress_delete_stdout.txt")
      exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
      exec("find output/test_actual/compress -print >output/test_actual/compress_delete_files.txt")
    end
    it "should leave the original directory alone" do
      "compress_files_before.txt".should match_expected_output
    end
    it "should create the proper files" do
      "compress_delete_files.txt".should match_expected_output
    end
    it "should write the proper messages on STDERR" do
      "compress_delete_stderr.txt".should match_expected_output
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/compress_delete_stdout.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/compress")
      exec_on_success("rm -rf output/test_actual/compress")
      exec_on_success("rm -rf output/test_actual/compress_delete_files.txt")
      exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
      exec_on_success("rm -rf output/test_actual/compress_delete_stdout.txt")
      exec_on_success("rm -rf output/test_actual/compress_delete_stderr.txt")
    end
  end
  context "to a new directory --link" do
    before :all do
      exec("rm -rf data/test/archive/compress")
      exec("rm -rf output/test_actual/compress")
      exec("rm -rf output/test_actual/compress_link_files.txt")
      exec("rm -rf output/test_actual/compress_link_links.txt")
      exec("rm -rf output/test_actual/compress_files_before.txt")
      exec("rm -rf output/test_actual/compress_link_stdout.txt")
      exec("rm -rf output/test_actual/compress_link_stderr.txt")
      exec("cp -r data/test/archive/compress_init data/test/archive/compress")
      exec("bun compress --link data/test/archive/compress output/test_actual/compress \
                2>output/test_actual/compress_link_stderr.txt \
                >output/test_actual/compress_link_stdout.txt")
      exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
      exec("find output/test_actual/compress -print >output/test_actual/compress_link_files.txt")
      exec("ls -l `find output/test_actual/compress -type l -print` | sed 's/^.*:[0-9][0-9] output/output/' >output/test_actual/compress_link_links.txt")
    end
    it "should leave the original directory alone" do
      "compress_files_before.txt".should match_expected_output
    end
    it "should create the proper files" do
      "compress_link_files.txt".should match_expected_output
    end
    it "should create the proper links" do
      "compress_link_links.txt".should match_expected_output
    end
    it "should write the proper messages on STDERR" do
      "compress_link_stderr.txt".should match_expected_output
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/compress_link_stdout.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/compress")
      exec_on_success("rm -rf output/test_actual/compress")
      exec_on_success("rm -rf output/test_actual/compress_link_files.txt")
      exec_on_success("rm -rf output/test_actual/compress_link_links.txt")
      exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
      exec_on_success("rm -rf output/test_actual/compress_link_stdout.txt")
      exec_on_success("rm -rf output/test_actual/compress_link_stderr.txt")
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
      exec("bun compress --delete data/test/archive/compress \
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
  context "with conflicts" do
    # Archive data/test/archive/compress_conflict_init should contain
    #   xxx.txt
    #   xxx/tape... (which will conflict with above)
    #   yyy.v1.txt
    #   yyy.v2.txt
    #   yyy_ddmmyy_hhmmss/tape... (which will conflict with all of the above)
    before :all do
      exec("rm -rf data/test/archive/compress_conflict")
      exec("rm -rf output/test_actual/compress_conflict")
      exec("rm -rf output/test_actual/compress_conflict_files.txt")
      exec("rm -rf output/test_actual/compress_conflict_files_before.txt")
      exec("rm -rf output/test_actual/compress_conflict_stdout.txt")
      exec("rm -rf output/test_actual/compress_conflict_stderr.txt")
      exec("cp -r data/test/archive/compress_conflict_init data/test/archive/compress_conflict")
      exec("find data/test/archive/compress_conflict -print >output/test_actual/compress_conflict_files_before.txt")
      exec("bun compress --delete data/test/archive/compress_conflict output/test_actual/compress_conflict \
                2>output/test_actual/compress_conflict_stderr.txt \
                >output/test_actual/compress_conflict_stdout.txt")
      exec("find output/test_actual/compress_conflict -print >output/test_actual/compress_conflict_files.txt")
    end
    it "should create the proper files" do
      "compress_conflict_files.txt".should match_expected_output
    end
    it "should leave the original directory alone" do
      "compress_conflict_files_before.txt".should match_expected_output
    end
    it "should write the proper messages on STDERR" do
      "compress_conflict_stderr.txt".should match_expected_output
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/compress_conflict_stdout.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/compress_conflict")
      exec_on_success("rm -rf output/test_actual/compress_conflict")
      exec_on_success("rm -rf output/test_actual/compress_conflict_files.txt")
      exec_on_success("rm -rf output/test_actual/compress_conflict_files_before.txt")
      exec_on_success("rm -rf output/test_actual/compress_conflict_stdout.txt")
      exec_on_success("rm -rf output/test_actual/compress_conflict_stderr.txt")
    end
  end
end
