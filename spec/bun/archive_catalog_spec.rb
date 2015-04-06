#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "archive catalog" do
  context "normal" do
    before :all do
      exec("rm -rf data/test/archive/catalog_source")
      exec("cp -r data/test/archive/catalog_source_init data/test/archive/catalog_source")
      exec("bun archive catalog data/test/archive/catalog_source --catalog data/test/catalog.txt \
                2>output/test_actual/archive_catalog_stderr.txt >output/test_actual/archive_catalog_stdout.txt")
    end
    it "should write nothing on stdout" do
      'output/test_actual/archive_catalog_stdout.txt'.should be_an_empty_file
    end
    it "should write messages on stderr" do
      "archive_catalog_stderr.txt".should match_expected_output
    end
    it "should not add or remove any files in the archive" do
      exec('find data/test/archive/catalog_source -print >output/test_actual/archive_catalog_files.txt')
      'archive_catalog_files.txt'.should match_expected_output
    end
    {
      'ar003.0698.bun'  =>'should', 
      'ar003.0701.bun' => 'should not',
      'ar082.0605.bun' => 'should',
      'ar083.0698.bun' => 'should'
    }.each do |file, disposition|
      context file do
        before :all do
          @catalog_describe_basename = "catalog_describe_#{file}"
          @catalog_describe_output_file = "output/test_actual/#{@catalog_describe_basename}"
          exec("rm -rf #{@catalog_describe_output_file}")
          exec("bun describe data/test/archive/catalog_source/#{file} >#{@catalog_describe_output_file}")
        end
        it "#{disposition} change the catalog dates and incomplete_file fields" do 
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
  context "with --quiet" do
    before :all do
      exec("rm -rf data/test/archive/catalog_source")
      exec("cp -r data/test/archive/catalog_source_init data/test/archive/catalog_source")
      exec("bun archive catalog --quiet data/test/archive/catalog_source --catalog data/test/catalog.txt \
                2>output/test_actual/archive_catalog_stderr.txt >output/test_actual/archive_catalog_stdout.txt")
    end
    it "should write nothing on stdout" do
      'output/test_actual/archive_catalog_stdout.txt'.should be_an_empty_file
    end
    it "should write nothing on stderr" do
      "output/test_actual/archive_catalog_stderr.txt".should be_an_empty_file
    end
    it "should not add or remove any files in the archive" do
      exec('find data/test/archive/catalog_source -print >output/test_actual/archive_catalog_files.txt')
      'archive_catalog_files.txt'.should match_expected_output
    end
    {
      'ar003.0698.bun'  =>'should', 
      'ar003.0701.bun' => 'should not',
      'ar082.0605.bun' => 'should',
      'ar083.0698.bun' => 'should'
    }.each do |file, disposition|
      context file do
        before :all do
          @catalog_describe_basename = "catalog_describe_#{file}"
          @catalog_describe_output_file = "output/test_actual/#{@catalog_describe_basename}"
          exec("rm -rf #{@catalog_describe_output_file}")
          exec("bun describe data/test/archive/catalog_source/#{file} >#{@catalog_describe_output_file}")
        end
        it "#{disposition} change the catalog dates and incomplete_file fields" do 
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
  context "to a new directory" do
    before :all do
      exec("rm -rf data/test/archive/catalog_source")
      exec("rm -rf output/test_actual/catalog_output_archive")
      exec("rm -rf output/test_actual/archive_catalog_to_dir_stdout.txt")
      exec("rm -rf output/test_actual/archive_catalog_to_dir_stderr.txt")
      exec("rm -rf output/test_actual/archive_catalog_to_dir_files.txt")
      exec("cp -r data/test/archive/catalog_source_init data/test/archive/catalog_source")
      exec("bun archive catalog data/test/archive/catalog_source \
                output/test_actual/catalog_output_archive \
                --catalog data/test/catalog.txt \
                2>output/test_actual/archive_catalog_to_dir_stderr.txt >output/test_actual/archive_catalog_to_dir_stdout.txt")
    end
    it "should create the directory" do 
      file_should_exist('output/test_actual/catalog_output_archive')
    end
    it "should write nothing on stdout" do
      'output/test_actual/archive_catalog_to_dir_stdout.txt'.should be_an_empty_file
    end
    it "should write messages on stderr" do
      "archive_catalog_to_dir_stderr.txt".should match_expected_output
    end
    it "should not add or remove any files in the original archive" do
      exec('find data/test/archive/catalog_source -print >output/test_actual/archive_catalog_to_dir_files.txt')
      'archive_catalog_to_dir_files.txt'.should match_expected_output
    end
    it "should copy all the files to the new archive" do
      exec('find output/test_actual/catalog_output_archive -print >output/test_actual/archive_catalog_to_dir_new_files.txt')
      'archive_catalog_to_dir_new_files.txt'.should match_expected_output
    end
    {
      'ar003.0698.bun'  =>'should', 
      'ar003.0701.bun' => 'should not',
      'ar082.0605.bun' => 'should',
      'ar083.0698.bun' => 'should'
    }.each do |file, disposition|
      context file do
        context "in the new archive" do
          before :all do
            @catalog_describe_basename = "catalog_describe_after_#{file}"
            @catalog_describe_output_file = "output/test_actual/#{@catalog_describe_basename}"
            exec("rm -rf #{@catalog_describe_output_file}")
            exec("bun describe output/test_actual/catalog_output_archive/#{file} >#{@catalog_describe_output_file}")
          end
          it "#{disposition} change the catalog dates and incomplete_file fields" do 
            @catalog_describe_basename.should match_expected_output_except_for(DESCRIBE_PATTERNS)
          end
          after :all do
            backtrace
            exec_on_success("rm -rf #{@catalog_describe_output_file}")
          end
        end
        context "in the original archive" do
          before :all do
            @catalog_describe_basename = "catalog_describe_before_#{file}"
            @catalog_describe_output_file = "output/test_actual/#{@catalog_describe_basename}"
            exec("rm -rf #{@catalog_describe_output_file}")
            exec("bun describe data/test/archive/catalog_source/#{file} >#{@catalog_describe_output_file}")
          end
          it "should not change the catalog dates and incomplete_file fields" do 
            @catalog_describe_basename.should match_expected_output_except_for(DESCRIBE_PATTERNS)
          end
          after :all do
            backtrace
            exec_on_success("rm -rf #{@catalog_describe_output_file}")
          end
        end
      end
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/catalog_source")
      exec_on_success("rm -rf output/test_actual/catalog_output_archive")
      exec_on_success("rm -rf output/test_actual/archive_catalog_to_dir_stdout.txt")
      exec_on_success("rm -rf output/test_actual/archive_catalog_to_dir_stderr.txt")
      exec_on_success("rm -f  output/test_actual/archive_catalog_to_dir_files.txt")
      exec_on_success("rm -f  output/test_actual/archive_catalog_to_dir_new_files.txt")
    end
  end
  context "to an existing directory" do
    context "without --force" do
      before :all do
        exec("rm -rf data/test/archive/catalog_source")
        exec("rm -rf output/test_actual/catalog_output_archive")
        exec("mkdir output/test_actual/catalog_output_archive")
        exec("rm -rf output/test_actual/archive_catalog_to_existing_dir_stdout.txt")
        exec("rm -rf output/test_actual/archive_catalog_to_existing_dir_stderr.txt")
        exec("rm -f output/test_actual/archive_catalog_existing_no_force_files.txt")
        exec("cp -r data/test/archive/catalog_source_init data/test/archive/catalog_source")
        exec("bun archive catalog data/test/archive/catalog_source \
                  output/test_actual/catalog_output_archive \
                  --catalog data/test/catalog.txt \
                  2>output/test_actual/archive_catalog_to_existing_dir_stderr.txt \
                  >output/test_actual/archive_catalog_to_existing_dir_stdout.txt",
                  allowed: [1])
      end
      it "should fail" do
        $?.exitstatus.should == 1
      end
      it "should write a message on stderr" do
        "archive_catalog_to_existing_dir_stderr.txt".should match_expected_output
      end
      it "should not change the new archive" do
        exec('find output/test_actual/catalog_output_archive -print >output/test_actual/archive_catalog_existing_no_force_files.txt')
        'archive_catalog_existing_no_force_files.txt'.should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/catalog_source")
        exec_on_success("rm -rf output/test_actual/catalog_output_archive")
        exec_on_success("rm -rf output/test_actual/archive_catalog_to_existing_dir_stdout.txt")
        exec_on_success("rm -rf output/test_actual/archive_catalog_to_exising_dir_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_catalog_existing_no_force_files.txt")
      end
    end
    context "with --force" do
      before :all do
        exec("rm -rf data/test/archive/catalog_source")
        exec("rm -rf output/test_actual/catalog_output_archive")
        exec("mkdir output/test_actual/catalog_output_archive")
        exec("rm -rf output/test_actual/archive_catalog_to_dir_stdout.txt")
        exec("rm -rf output/test_actual/archive_catalog_to_dir_stderr.txt")
        exec("rm -rf output/test_actual/archive_catalog_to_dir_files.txt")
        exec("cp -r data/test/archive/catalog_source_init data/test/archive/catalog_source")
        exec("bun archive catalog --force data/test/archive/catalog_source \
                  output/test_actual/catalog_output_archive \
                  --catalog data/test/catalog.txt \
                  2>output/test_actual/archive_catalog_to_dir_stderr.txt >output/test_actual/archive_catalog_to_dir_stdout.txt")
      end
      it "should create the directory" do 
        file_should_exist('output/test_actual/catalog_output_archive')
      end
      it "should write nothing on stdout" do
        'output/test_actual/archive_catalog_to_dir_stdout.txt'.should be_an_empty_file
      end
      it "should write messages on stderr" do
        "archive_catalog_to_dir_stderr.txt".should match_expected_output
      end
      it "should not add or remove any files in the original archive" do
        exec('find data/test/archive/catalog_source -print >output/test_actual/archive_catalog_files.txt')
        'archive_catalog_files.txt'.should match_expected_output
      end
      it "should copy all the files to the new archive" do
        exec('find output/test_actual/catalog_output_archive -print >output/test_actual/archive_catalog_to_dir_new_files.txt')
        'archive_catalog_to_dir_new_files.txt'.should match_expected_output
      end
      {
        'ar003.0698.bun'  =>'should', 
        'ar003.0701.bun' => 'should not',
        'ar082.0605.bun' => 'should',
        'ar083.0698.bun' => 'should'
      }.each do |file, disposition|
        context file do
          context "in the new archive" do
            before :all do
              @catalog_describe_basename = "catalog_describe_after_#{file}"
              @catalog_describe_output_file = "output/test_actual/#{@catalog_describe_basename}"
              exec("rm -rf #{@catalog_describe_output_file}")
              exec("bun describe output/test_actual/catalog_output_archive/#{file} >#{@catalog_describe_output_file}")
            end
            it "#{disposition} change the catalog dates and incomplete_file fields" do 
              @catalog_describe_basename.should match_expected_output_except_for(DESCRIBE_PATTERNS)
            end
            after :all do
              backtrace
              exec_on_success("rm -rf #{@catalog_describe_output_file}")
            end
          end
          context "in the original archive" do
            before :all do
              @catalog_describe_basename = "catalog_describe_before_#{file}"
              @catalog_describe_output_file = "output/test_actual/#{@catalog_describe_basename}"
              exec("rm -rf #{@catalog_describe_output_file}")
              exec("bun describe data/test/archive/catalog_source/#{file} >#{@catalog_describe_output_file}")
            end
            it "should not change the catalog dates and incomplete_file fields" do 
              @catalog_describe_basename.should match_expected_output_except_for(DESCRIBE_PATTERNS)
            end
            after :all do
              backtrace
              exec_on_success("rm -rf #{@catalog_describe_output_file}")
            end
          end
        end
      end
      after :all do
        backtrace
        exec_on_success("rm -rf data/test/archive/catalog_source")
        exec_on_success("rm -rf output/test_actual/catalog_output_archive")
        exec_on_success("rm -rf output/test_actual/archive_catalog_to_dir_stdout.txt")
        exec_on_success("rm -rf output/test_actual/archive_catalog_to_dir_stderr.txt")
        exec_on_success("rm -f output/test_actual/archive_catalog_to_dir_files.txt")
        exec_on_success("rm -f output/test_actual/archive_catalog_to_dir_new_files.txt")
      end
    end
  end
  context "mixed archive" do
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
      "mixed_formats_catalog/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229".should \
          match_expected_output
      "mixed_formats_catalog/fass/script/tape.ar004.0642_19770224".should match_expected_output_except_for(DECODE_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/mixed_formats")
      exec_on_success("rm -rf output/test_actual/mixed_formats_catalog")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_catalog.txt")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
    end
  end
end
