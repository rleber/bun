#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'tempfile'
require 'yaml'

def exec(cmd, options={})
  res = `#{cmd}`
  unless $?.exitstatus == 0
    allowed_codes = [options[:allowed] || []].flatten
    unless allowed_codes.include?(:all)
      raise RuntimeError, "Command #{cmd} failed with exit status #{$?.exitstatus}" unless allowed_codes.include?($?.exitstatus)
    end
  end
  res
end

def decode(file_name)
  archive = Bun::Archive.new
  expanded_file = File.join("data", "test", file_name)
  file = Bun::File::Text.open(expanded_file)
  file.text
end

def scrub(lines, options={})
  tabs = options[:tabs] || '80'
  tempfile = Tempfile.new('bun1')
  tempfile2 = Tempfile.new('bun2')
  tempfile.write(lines)
  tempfile.close
  tempfile2.close
  system("cat #{tempfile.path.inspect} | ruby -p -e '$_.gsub!(/_\\x8/,\"\")' | expand -t #{tabs} >#{tempfile2.path.inspect}")
  rstrip(Bun.readfile(tempfile2.path))
end

def decode_and_scrub(file, options={})
  scrub(decode(file), options)
end

def rstrip(text)
  text.split("\n").map{|line| line.rstrip }.join("\n")
end

shared_examples "simple" do |file|
  it "decodes a simple text file (#{file})" do
    infile = file
    outfile = File.join("output", "test", infile)
    decode(infile).should == Bun.readfile(outfile)
  end
end

shared_examples "command" do |descr, command, expected_stdout_file, options={}|
  it "handles #{descr} properly" do
    # warn "> bun #{command}"
    res = exec("bun #{command} 2>&1", options).force_encoding('ascii-8bit')
    expected_stdout_file = File.join("output", 'test', expected_stdout_file) unless expected_stdout_file =~ %r{/}  
    rstrip(res).should == rstrip(Bun.readfile(expected_stdout_file))
  end
end

shared_examples "command with file" do |descr, command, expected_stdout_file, output_file, expected_output_file|
  context descr do
    before :all do
      # warn "> bun #{command}"
      @res = exec("bun #{command} 2>&1")
      @expected_stdout_file = if expected_stdout_file =~ %r{/}
        expected_stdout_file
      else 
        File.join("output", 'test', expected_stdout_file)
      end
      @expected_output_file = if expected_output_file =~ %r{/}
        expected_output_file
      else
        File.join("output", 'test', expected_output_file)
      end
      @output_file = if output_file =~ %r{/}
        output_file
      else
        File.join("output", output_file)
      end
    end
    it "gives the expected $stdout" do
      @res.should == Bun.readfile(@expected_stdout_file)
    end
    it "creates the expected output file (#{output_file})" do
      file_should_exist @output_file
    end
    it "puts the expected output (in #{output_file})" do
      if File.exists?(@output_file) 
        Bun.readfile(@output_file).should == Bun.readfile(@expected_output_file)
      end
    end
    after :all do
      exec("rm #{@output_file}")
    end
  end
end

describe Bun::File::Text do
  include_examples "simple", "ar119.1801"
  include_examples "simple", "ar003.0698"
  
  it "decodes a more complex file (ar004.0642)" do
    infile = 'ar004.0642'
    outfile = File.join("output", "test", infile)
    decode_and_scrub(infile, :tabs=>'80').should == rstrip(Bun.readfile(outfile))
  end
end

describe Bun::Archive do
  before :each do
    @archive = Bun::Archive.new(:at=>'data/test/archive/contents')
  end
  describe "contents" do
    it "retrieves correct list" do
      @archive.contents.sort.should == %w{ar003.0698 ar054.2299::brytside ar054.2299::disco 
                                          ar054.2299::end ar054.2299::opening ar054.2299::santa }
    end
    it "invokes a block" do
      foo = []
      @archive.contents {|f| foo << f }
      foo.sort.should == %w{ar003.0698 ar054.2299::brytside ar054.2299::disco 
                            ar054.2299::end ar054.2299::opening ar054.2299::santa }
    end
  end
end

# Frozen files to check ar013.0560, ar004.0888, ar019.0175

describe Bun::Bot do
  # include_examples "command", "descr", "cmd", "expected_stdout_file"
  # include_examples "command with file", "descr", "cmd", "expected_stdout_file", "output_in_file", "expected_output_file"
  describe "check" do
    include_examples "command", "check clean file", "check data/test/clean", "check_clean"
    include_examples "command", "check dirty file", "check data/test/ar119.1801", "check_dirty", :allowed=>[1]
  end
    
  describe "describe" do
    include_examples "command", "describe text file", "describe ar003.0698", "describe_ar003.0698"
    include_examples "command", "describe frozen file", "describe ar025.0634", "describe_ar025.0634"
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
      exec("cd ~/bun_archive ; bun describe ar003.0698")
      $?.exitstatus.should == 0
    end
    after :each do
      Dir.chdir(@original_dir)
      raise RuntimeError, "Not back in normal working directory: #{Dir.pwd}" \
        unless File.expand_path(Dir.pwd) == File.expand_path(File.join(File.dirname(__FILE__),'..'))
    end
  end
  
  describe "ls" do
    include_examples "command", "ls", "ls", "ls"
    include_examples "command", "ls -ldr with text file (ar003.0698)", "ls -ldr -h ar003.0698", "ls_ldrh_ar003.0698"
    include_examples "command", "ls -ldr with frozen file (ar145.2699)", "ls -ldr -h ar145.2699", "ls_ldrh_ar145.2699"
    include_examples "command", "ls -ldrb with frozen file (ar145.2699)", "ls -ldrb -h ar145.2699", "ls_ldrbh_ar145.2699"
  end
  describe "readme" do
    include_examples "command", "readme", "readme", "doc/readme.md"
  end
  describe "unpack" do
    include_examples "command", "unpack", "unpack ar003.0698", "unpack"
  end
  describe "cat" do
    include_examples "command", "cat (ar003.0698)", "cat ar003.0698", "cat"
  end
  describe "cp" do
    include_examples "command with file", 
      "cp ar003.0698 output/cp_ar003.0698.out", "cp ar003.0698 output/cp_ar003.0698.out", 
      "cp_ar003.0698.stdout", "cp_ar003.0698.out", "cp_ar003.0698"
    include_examples "command", "cp ar003.0698 -", "cp ar003.0698 -", "cp_ar003.0698"
    include_examples "command", "cp ar003.0698", "cp ar003.0698", "cp_ar003.0698"
    include_examples "command with file", 
      "cp ar003.0698 output/cp_ar003.0698 (a directory)", "cp ar003.0698 output/cp_ar003.0698", 
      "cp_ar003.0698.stdout", "output/cp_ar003.0698/ar003.0698", "cp_ar003.0698"
    context "multiple files" do
      before :each do
        exec("rm -rf output/multiple_cp")
        exec("mkdir output/multiple_cp")
        exec("bun cp 'ar*.0698' 'ar*.0605' output/multiple_cp 2>&1")
      end
      it "should copy 3 files" do
        expected_files = %w{ar003.0698 ar082.0605 ar083.0698}.sort
        result_files = Dir.glob('output/multiple_cp/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
        result_files.should == expected_files
      end
      after :each do
        exec("rm -rf output/multiple_cp")
      end
    end
    describe "recursive" do
      before :each do
        exec("rm -rf data/test/archive/cp_recursive")
        exec("rm -rf data/test/archive/cp_recursive_new")
        exec("cp -r  data/test/archive/cp_recursive_init data/test/archive/cp_recursive")
        exec("mkdir  data/test/archive/cp_recursive_new")
        exec("bun cp -r --at data/test/archive/cp_recursive '*' '@/../cp_recursive_new/'")
      end
      describe "creates files" do
        before :each do
          exec "rm -f output/cp_recursive_files"
          exec "find data/test/archive/cp_recursive -print > output/cp_recursive_files"
        end
        it "as expected" do
          Bun.readfile('output/cp_recursive_files').should == Bun.readfile('output/test/cp_recursive_files')
        end
        after :each do
          exec "rm -f output/cp_recursive_files"
        end
      end
      describe "the original files" do
        describe "in the main directory" do
          it "are unchanged" do
            expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698 directory}.sort
            result_files = Dir.glob('data/test/archive/cp_recursive/*').map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
        end
        describe "in the sub-directory" do
          it "are unchanged" do
            expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort
            result_files = Dir.glob('data/test/archive/cp_recursive/directory/subdirectory/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
        end
      end
      describe "the original indexes" do
        describe "in the main directory" do
          it "are unchanged" do
            expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort.map{|f| "#{f}.descriptor.yml"}
            result_files = Dir.glob('data/test/archive/cp_recursive/.bun_index/*').map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
        end
        describe "in the sub-directory" do
          it "are unchanged" do
            expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort.map{|f| "#{f}.descriptor.yml"}
            result_files = Dir.glob('data/test/archive/cp_recursive/directory/subdirectory/.bun_index/*').map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
        end
      end
      describe "the new files" do
        describe "in the main directory" do
          it "are all copied" do
            expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698 directory}.sort
            result_files = Dir.glob('data/test/archive/cp_recursive_new/*').map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
        end
        describe "in the sub-directory" do
          it "are all copied" do
            expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort
            result_files = Dir.glob('data/test/archive/cp_recursive_new/directory/subdirectory/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
        end
      end
      describe "the new indexes" do
        describe "in the main directory" do
          it "are all created" do
            expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort.map{|f| "#{f}.descriptor.yml"}
            result_files = Dir.glob('data/test/archive/cp_recursive_new/.bun_index/*').map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
          it "should not change the hoard" do
            content = YAML.load(Bun.readfile("data/test/archive/cp_recursive_new/.bun_index/ar003.0701.descriptor.yml", :encoding=>'us-ascii'))
            content[:hoard].should == 'ar003.0701'
          end
          it "should change the hoard_path" do
            content = YAML.load(Bun.readfile("data/test/archive/cp_recursive_new/.bun_index/ar003.0701.descriptor.yml", :encoding=>'us-ascii'))
            content[:hoard_path].should == %{#{exec("pwd").chomp}/data/test/archive/cp_recursive_new/ar003.0701}
          end
        end
        describe "in the sub-directory" do
          it "are all created" do
            expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort.map{|f| "#{f}.descriptor.yml"}
            result_files = Dir.glob('data/test/archive/cp_recursive_new/directory/subdirectory/.bun_index/*').map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
          it "should not change the hoard" do
            content = YAML.load(Bun.readfile("data/test/archive/cp_recursive_new/.bun_index/ar082.0605.descriptor.yml", :encoding=>'us-ascii'))
            content[:hoard].should == 'ar082.0605'
          end
          it "should change the hoard_path" do
            content = YAML.load(Bun.readfile("data/test/archive/cp_recursive_new/.bun_index/ar082.0605.descriptor.yml", :encoding=>'us-ascii'))
            content[:hoard_path].should == %{#{exec("pwd").chomp}/data/test/archive/cp_recursive_new/ar082.0605}
          end
        end
      end
      after :each do
        exec("rm -rf data/test/archive/cp_recursive")
        exec("rm -rf data/test/archive/cp_recursive_new")
      end
    end
    context "index processing" do
      context "for a single file" do
        before :all do
          # warn "> bun #{command}"
          exec("rm -rf output/.bun_index")
          exec("rm -f output/cp_ar003.0698.out")
          exec("bun cp ar003.0698 output/cp_ar003.0698.out 2>&1")
        end
        it "creates an index" do
          file_should_exist "output/.bun_index/cp_ar003.0698.out.descriptor.yml"
        end
        context "contents of index" do
          before :each do
            @original_content = YAML.load(Bun.readfile("#{ENV['HOME']}/bun_archive/.bun_index/ar003.0698.descriptor.yml", :encoding=>'us-ascii'))
            @content = YAML.load(Bun.readfile("output/.bun_index/cp_ar003.0698.out.descriptor.yml", :encoding=>'us-ascii'))
          end
          it "should change the hoard" do
            @content[:hoard].should == 'cp_ar003.0698.out'
          end
          it "should change the hoard_path" do
            @content[:hoard_path].should == %{#{exec("pwd").chomp}/output/cp_ar003.0698.out}
          end
          it "should record the original hoard" do
            @content[:original_hoard].should == 'ar003.0698'
          end
          it "should record the original hoard_path" do
            @content[:original_hoard_path].should == "#{ENV['HOME']}/bun_archive/ar003.0698"
          end
          it "should otherwise match the original index" do
            other_content = @content.dup
            other_content.delete(:hoard)
            other_content.delete(:hoard_path)
            other_content.delete(:original_hoard)
            other_content.delete(:original_hoard_path)
            other_original_content = @original_content.dup
            other_original_content.delete(:hoard)
            other_original_content.delete(:hoard_path)
            other_original_content.delete(:original_hoard)
            other_original_content.delete(:original_hoard_path)
            other_content.should == other_original_content
          end
        end
        after :all do
          exec("rm -f output/cp_ar003.0698.out")
          exec("rm -rf output/.bun_index")
        end
      end
      context "for a directory of files" do
        before :all do
          # warn "> bun #{command}"
          exec("rm -rf output/cp_ar003.0698/.bun_index")
          exec("rm -f output/cp_ar003.0698/ar003.0698")
          exec("bun cp ar003.0698 output/cp_ar003.0698 2>&1")
        end
        it "creates an index" do
          file_should_exist "output/cp_ar003.0698/.bun_index/ar003.0698.descriptor.yml"
        end
        after :all do
          exec("rm -f output/cp_ar003.0698/ar003.0698")
          exec("rm -rf output/cp_ar003.0698/.bun_index")
        end
      end
      context "with --bare" do
        before :all do
          # warn "> bun #{command}"
          exec("rm -rf output/.bun_index")
          exec("rm -f output/cp_ar003.0698.out")
          exec("bun cp --bare ar003.0698 output/cp_ar003.0698.out 2>&1")
        end
        it "does not creates an index" do
          file_should_not_exist "output/.bun_index"
        end
        after :all do
          exec("rm -f output/cp_ar003.0698.out")
          exec("rm -rf output/.bun_index")
        end
      end
    end
  end
  describe "rm" do
    before :each do
      exec("rm -rf data/test/archive/rm")
      exec("cp -r  data/test/archive/rm_init data/test/archive/rm")
    end
    describe "with one file" do
      describe "non-recursive" do
        before :each do
          exec("bun rm --at data/test/archive/rm ar003.0701")
        end
        it "removes the file" do
          expected_files = %w{ar003.0698 ar082.0605 ar083.0698}.sort
          result_files = Dir.glob('data/test/archive/rm/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
          result_files.should == expected_files
        end
        it "removes the file from the index" do
          expected_files = %w{ar003.0698 ar082.0605 ar083.0698}.map{|name| name + '.descriptor.yml'}.sort
          result_files = Dir.glob('data/test/archive/rm/.bun_index/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
          result_files.should == expected_files
        end
        it "should refuse to remove a directory" do
          exec("bun rm --at data/test/archive/rm directory 2>&1", :allowed=>:all)
          $?.exitstatus.should_not == 0
        end
      end
      describe "recursive" do
        describe "with non-directory" do
          before :each do
            exec("bun rm -r --at data/test/archive/rm ar003.0701")
          end
          it "removes the file" do
            expected_files = %w{ar003.0698 ar082.0605 ar083.0698}.sort
            result_files = Dir.glob('data/test/archive/rm/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
          it "removes the file from the index" do
            expected_files = %w{ar003.0698 ar082.0605 ar083.0698}.map{|name| name + '.descriptor.yml'}.sort
            result_files = Dir.glob('data/test/archive/rm/.bun_index/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
        end
        describe "with directory" do
          before :each do
            exec("bun rm -r --at data/test/archive/rm directory")
          end
          it "removes the file" do
            expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort
            result_files = Dir.glob('data/test/archive/rm/*').map{|f| File.basename(f)}.sort
            result_files.should == expected_files
          end
        end
      end
    end
    describe "with multiple files" do
      before :each do
        exec("bun rm --at data/test/archive/rm '*.0698'")
      end
      it "removes the files" do
        expected_files = %w{ar003.0701 ar082.0605}.sort
        result_files = Dir.glob('data/test/archive/rm/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
        result_files.should == expected_files
      end
      it "removes the files from the index" do
        expected_files = %w{ar003.0701 ar082.0605}.map{|name| name + '.descriptor.yml'}.sort
        result_files = Dir.glob('data/test/archive/rm/.bun_index/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
        result_files.should == expected_files
      end
    end
    after :each do
      exec("rm -rf data/test/archive/rm")
    end
  end
  describe "mv" do
    before :each do
      exec("rm -rf data/test/archive/mv")
      exec("cp -r  data/test/archive/mv_init data/test/archive/mv")
    end
    describe "with a non-directory" do
      before :each do
        exec("bun mv --at data/test/archive/mv ar003.0701 ar003.0701b")
      end
      it "moves the file in the index" do
        expected_files = %w{ar003.0698 ar003.0701b ar082.0605 ar083.0698}.map{|name| name + '.descriptor.yml'}.sort
        result_files = Dir.glob('data/test/archive/mv/.bun_index/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
        result_files.should == expected_files
      end
      it "should change the hoard" do
        content = YAML.load(Bun.readfile("data/test/archive/mv/.bun_index/ar003.0701b.descriptor.yml", :encoding=>'us-ascii'))
        content[:hoard].should == 'ar003.0701b'
      end
      it "should change the hoard_path" do
        content = YAML.load(Bun.readfile("data/test/archive/mv/.bun_index/ar003.0701b.descriptor.yml", :encoding=>'us-ascii'))
        content[:hoard_path].should == %{#{exec("pwd").chomp}/data/test/archive/mv/ar003.0701b}
      end
    end
    describe "with a directory" do
      before :each do
        exec("bun mv --at data/test/archive/mv directory directory2")
      end
      it "moves the directory" do
        expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698 directory2}.sort
        result_files = Dir.glob('data/test/archive/mv/*').map{|f| File.basename(f)}.sort
        result_files.should == expected_files
      end
      it "moves the contents of the directory" do
        expected_files = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort
        result_files = Dir.glob('data/test/archive/mv/directory2/*').reject{|f| File.directory?(f)}.map{|f| File.basename(f)}.sort
        result_files.should == expected_files
      end
      it "should leave the hoards unchanged" do
        expected_hoards = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort
        hoards = []
        Dir.glob("data/test/archive/mv/directory2/.bun_index/*.descriptor.yml").each do |f|
          hoards << YAML.load(Bun.readfile(f, :encoding=>'us-ascii'))[:hoard]
        end
        hoards.sort.should == expected_hoards
      end
      it "should change the hoard_paths" do
        expected_hoard_paths = %w{ar003.0698 ar003.0701 ar082.0605 ar083.0698}.sort.map do |f|
          %{#{exec("pwd").chomp}/data/test/archive/mv/directory2/#{f}}
        end
        hoard_paths = []
        Dir.glob("data/test/archive/mv/directory2/.bun_index/*.descriptor.yml").each do |f|
          hoard_paths << YAML.load(Bun.readfile(f, :encoding=>'us-ascii'))[:hoard_path]
        end
        hoard_paths.sort.should == expected_hoard_paths
      end
    end
    after :each do
      exec("rm -rf data/test/archive/mv")
    end
  end
  describe "mkdir" do
    before :each do
      exec("rm -rf output/mkdir")
    end
    describe "without -p" do
      it "should create a directory" do
        archive = Bun::Archive.new(:at=>"output")
        archive.mkdir('mkdir')
        file_should_exist "output/mkdir"
      end
      it "should not create a directory without parents" do
        archive = Bun::Archive.new(:at=>"output")
        expect { archive.mkdir('mkdir/foo') }.should raise_error
      end
    end
    describe "with -p" do
      it "should create a directory" do
        archive = Bun::Archive.new(:at=>"output")
        archive.mkdir('mkdir/foo/bar', :p=>true)
        file_should_exist "output/mkdir/foo/bar"
      end
      it "should create parent directories" do
        archive = Bun::Archive.new(:at=>"output")
        archive.mkdir('mkdir/foo/bar', :parents=>true)
        file_should_exist "output/mkdir"
      end
    end
    after :each do
      exec("rm -rf output/mkdir")
    end
  end
  context "index processing" do
    before :each do
      exec("rm -rf data/test/archive/index")
      exec("cp -r data/test/archive/init data/test/archive/index")
    end
    context "index build" do
      before :each do
        exec("rm -rf data/test/archive/index/.bun_index")
        exec("bun archive index build --at \"data/test/archive/index\"")
      end
      it "should create index" do
        file_should_exist "data/test/archive/index/.bun_index"
      end
      it "should have an entry for ar003.0698" do
        Dir.glob("data/test/archive/index/.bun_index/*").should == ["data/test/archive/index/.bun_index/ar003.0698.descriptor.yml"]
      end
      context "index contents" do
        before :each do
          content = Bun.readfile("data/test/archive/index/.bun_index/ar003.0698.descriptor.yml", :encoding=>'us-ascii')
          @index = YAML.load(content) rescue nil
        end
        it "should be a Hash" do
          @index.should be_a(Hash)
        end
      end
    end
    context "index clear" do
      before :each do
        exec("rm -rf data/test/archive/index/.bun_index")
        exec("bun archive index build --at \"data/test/archive/index\"")
        exec("bun archive index clear --at \"data/test/archive/index\"")
      end
      it "should remove index" do
        file_should_not_exist "data/test/archive/index/.bun_index"
      end
    end
    after :each do
      exec("rm -rf data/test/archive/index")
    end
  end
  context "bun ls handling of the index" do
    context "from the index" do
      before :each do
        exec("rm -rf data/test/archive/strange")
        exec("cp -r data/test/archive/strange_init data/test/archive/strange")
        lines = exec("bun ls --at \"data/test/archive/strange\" | tail -n 1").chomp
        @file = lines.split(/\s+/)[-1].strip
      end
      it "should pull data from the index" do
        @file.should == "path_from_the_index"
      end
      after :each do
        exec("rm -rf data/test/archive/strange")
      end
    end
    context "built from the file" do
      before :each do
        exec("rm -rf data/test/archive/strange")
        exec("cp -r data/test/archive/strange_init data/test/archive/strange")
        lines = exec("bun ls --at \"data/test/archive/strange\" --build | tail -n 1").chomp
        @file = lines.split(/\s+/)[-1].strip
      end
      it "should not pull data from the index" do
        @file.should_not == "path_from_the_index"
      end
      after :each do
        exec("rm -rf data/test/archive/strange")
      end
    end
  end
  context "bun describe handling of the index" do
    context "from the index" do
      before :each do
        exec("rm -rf data/test/archive/strange")
        exec("cp -r data/test/archive/strange_init data/test/archive/strange")
        lines = exec("bun describe --at \"data/test/archive/strange\" ar003.0698").chomp.split("\n")
        @file = lines.find {|line| line =~ /^Basename:/}.split(/\s+/)[1].strip
      end
      it "should pull data from the index" do
        @file.should == "basename_from_the_index"
      end
      after :each do
        exec("rm -rf data/test/archive/strange")
      end
    end
    context "built from the file" do
      before :each do
        exec("rm -rf data/test/archive/strange")
        exec("cp -r data/test/archive/strange_init data/test/archive/strange")
        lines = exec("bun describe --at \"data/test/archive/strange\" --build ar003.0698").chomp.split("\n")
        @file = lines.find {|line| line =~ /^Basename:/}.split(/\s+/)[-1].strip
      end
      it "should not pull data from the index" do
        @file.should_not == "basename_from_the_index"
      end
      after :each do
        exec("rm -rf data/test/archive/strange")
      end
    end
  end
  context "bun dump" do
    include_examples "command", "dump ar003.0698", "dump ar003.0698", "dump_ar003.0698"
    include_examples "command", "dump -s ar003.0698", "dump -s ar003.0698", "dump_s_ar003.0698"
    include_examples "command", "dump -f ar004.0888", "dump -f ar004.0888", "dump_f_ar004.0888"
  end
  context "bun freezer" do
    context "ls" do
      include_examples "command", "freezer ls ar004.0888", "freezer ls ar004.0888", "freezer_ls_ar004.0888"
      include_examples "command", "freezer ls -l ar004.0888", "freezer ls -l ar004.0888", "freezer_ls_l_ar004.0888"
      include_examples "command", "freezer ls -d ar004.0888", "freezer ls -d ar004.0888", "freezer_ls_d_ar004.0888"
    end
    context "dump" do
      include_examples "command", "freezer dump ar004.0888 +0", "freezer dump ar004.0888 +0", "freezer_dump_ar004.0888_0"
      include_examples "command", "freezer dump -s ar004.0888 +0", "freezer dump -s ar004.0888 +0", "freezer_dump_s_ar004.0888_0"
    end
    context "thaw" do
      include_examples "command", "freezer thaw ar004.0888 +0", "freezer thaw ar004.0888 +0", "freezer_thaw_ar004.0888_0"
    end
  end
  context "bun archive extract" do
    before :all do
      exec("rm -rf data/test/archive/extract_source")
      exec("rm -rf data/test/archive/extract_library")
      exec("cp -r data/test/archive/extract_source_init data/test/archive/extract_source")
      exec("bun archive extract --at data/test/archive/extract_source data/test/archive/extract_library 2>output/archive_extract_stderr.txt >output/archive_extract_stdout.txt")
    end
    it "should create a hoards directory" do
      file_should_exist "data/test/archive/extract_library"
    end
    it "should write nothing on stdout" do
      Bun.readfile('output/archive_extract_stdout.txt').chomp.should == ""
    end
    it "should write file decoding messages on stderr" do
      Bun.readfile("output/archive_extract_stderr.txt").chomp.should == Bun.readfile('output/test/archive_extract_stderr.txt').chomp
    end
    it "should create the appropriate files" do
      exec('find data/test/archive/extract_library -print >output/archive_extract_files.txt')
      Bun.readfile('output/archive_extract_files.txt').chomp.should == Bun.readfile('output/test/archive_extract_files.txt').chomp
    end
    describe "the index" do
      it "should exist" do
        file_should_exist "data/test/archive/extract_library/fass/1983/programme/actors/.bun_index/hoard.ar083.0698_19830128.txt.descriptor.yml"
      end
      describe "contents" do
        before :each do
          @original_content = YAML.load(Bun.readfile("data/test/archive/extract_source/.bun_index/ar083.0698.descriptor.yml", :encoding=>'us-ascii'))
          @content = YAML.load(Bun.readfile("data/test/archive/extract_library/fass/1983/programme/actors/.bun_index/hoard.ar083.0698_19830128.txt.descriptor.yml", :encoding=>'us-ascii'))
        end
        it "should change the hoard" do
          @content[:hoard].should == 'hoard.ar083.0698_19830128.txt'
        end
        it "should change the hoard_path" do
          @content[:hoard_path].should == %{#{exec("pwd").chomp}/data/test/archive/extract_library/fass/1983/programme/actors/hoard.ar083.0698_19830128.txt}
        end
        it "should record the original hoard" do
          @content[:original_hoard].should == 'ar083.0698'
        end
        it "should record the original hoard_path" do
          @content[:original_hoard_path].should == %{#{exec("pwd").chomp}/data/test/archive/extract_source/ar083.0698}
        end
        it "should record the extract time" do
          @content[:extracted].should be_a(Time)
        end
      end
    end
    after :all do
      exec("rm -rf data/test/archive/extract_source")
      exec("rm -rf data/test/archive/extract_library")
      exec("rm -f output/archive_extract_stderr.txt")
      exec("rm -f output/archive_extract_stdout.txt")
      exec("rm -f output/archive_extract_files.txt")
    end
  end
  context "bun catalog ls" do
    before :all do
      exec("bun catalog ls 2>&1 >output/catalog_ls")
    end
    it "should give correct output" do
      Bun.readfile("output/catalog_ls").should == Bun.readfile("output/test/catalog_ls")
    end
    after :all do
      exec("rm -rf output/catalog_ls")
    end
  end
  context "bun library compact" do
    before :each do
      exec("rm -rf data/test/archive/compact_files")
      exec("rm -rf data/test/archive/compact_result")
      exec("cp -r data/test/archive/compact_files_init data/test/archive/compact_files")
      exec("bun library compact data/test/archive/compact_files data/test/archive/compact_result")
    end
    it "should create the results directory" do
      file_should_exist "data/test/archive/compact_result"
    end
    # after :each do
    #   exec("rm -rf data/test/archive/compact_source")
    #   exec("rm -rf data/test/archive/compact_result")
    # end
  end
end