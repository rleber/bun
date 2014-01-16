#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/string'

no_tasks do
  def _exec(command)
    $stderr.puts command
    unless system(command)
      stop "!Command failed with code #{$?}"
    end
  end
  
  def build_file(file, at=nil, format=:unpacked)
    from = case format
    when :packed
      "~/fass_work/packed" 
    when :unpacked
      "~/fass_work/unpacked"
    when :cataloged
      "~/fass_work/cataloged"
    when :decoded
      "~/fass_work/decoded"
    when :baked
      "~/fass_work/baked"
    else
      raise "Unknown format: #{format}"
    end
    # TODO Move this to Bun class
    extension = case format
    when :packed
      Bun::DEFAULT_PACKED_FILE_EXTENSION
    when :unpacked
      Bun::DEFAULT_UNPACKED_FILE_EXTENSION
    when :cataloged
      Bun::DEFAULT_CATALOGED_FILE_EXTENSION
    when :decoded
      Bun::DEFAULT_DECODED_FILE_EXTENSION
    else
      Bun::DEFAULT_BAKED_FILE_EXTENSION
    end
    at = $at unless at
    file_with_extension = file + extension
    source_file = File.join(File.expand_path(from),file_with_extension)
    target_file = File.join(File.expand_path(at),file_with_extension)
    stop "!Source file #{source_file.safe} does not exist" unless File.exists?(source_file)
    cmd = "mkdir -p #{File.dirname(target_file).safe}"
    _exec cmd
    cmd = "cp -f #{source_file.safe} #{target_file.safe}"
    _exec cmd
  end
  
  def build_directory(at, &blk)
    _exec "rm -rf #{at.safe}"
    _exec "mkdir -p #{at.safe}"
    $at = at
    yield
  end
  
  def build_contents(at, format=:cataloged)
    build_directory(at) do
      build_file "ar003.0698", nil, format
      build_file "ar054.2299", nil, format
    end
  end
  
  def build_standard_directory(at, format=:cataloged)
    build_directory(at) do
      build_file "ar003.0698", nil, format
      build_file "ar003.0701", nil, format
      build_file "ar082.0605", nil, format
      build_file "ar083.0698", nil, format
    end
  end
  
  def build_general_test(at, format=:cataloged)
    build_directory(at) do
      build_file "ar003.0698", nil, format
      build_file "ar003.0701", nil, format
      build_file "ar004.0888", nil, format
      build_file "ar019.0175", nil, format
      build_file "ar025.0634", nil, format
      build_file "ar082.0605", nil, format
      build_file "ar083.0698", nil, format
      build_file "ar145.2699", nil, format
    end
  end
end

desc "build", "Build test files"
def build
  build_directory "data/test" do
    _exec "rm -rf data/test"
    _exec "cp -rf data/test_init data/test"
  end
  
  build_file "ar003.0698", "data/test"
  build_file "ar004.0642", "data/test"
  build_file "ar019.0175", "data/test"
  build_file "ar119.1801", "data/test"
  
  build_standard_directory "data/test/archive/catalog_source_init", :unpacked
  
  $stderr.puts "Not rebuilding data/test/archive/compact_files_init"
  
  build_directory "data/test/archive/compact_source_init" do
    build_file "ar004.0888"
    build_file "ar009.2622"
    build_file "ar010.0006"
    build_file "ar013.0560"
    build_file "ar019.0175"
    build_file "ar019.1842"
    build_file "ar077.0633"
    build_file "ar103.1065"
    build_file "ar108.2439"
    build_file "ar114.1860"
    build_file "ar116.1647"
    build_file "ar119.1124"
    build_file "ar126.0345"
  end
  
  build_contents "data/test/archive/contents"
  build_contents "data/test/archive/contents_packed", :packed

  build_standard_directory "data/test/archive/decode_source_init"
  
  build_general_test "data/test/archive/general_test"
  build_general_test "data/test/archive/general_test_packed_init", :packed

  build_directory "data/test/archive/init" do
    build_file "ar003.0698", nil, :packed
  end

  build_standard_directory "data/test/archive/mv_init"
  build_standard_directory "data/test/archive/mv_init/directory"
  build_standard_directory "data/test/archive/rm_init"
  build_standard_directory "data/test/archive/rv_init/directory"

  # Build mixed directory
  build_directory "data/test/archive/mixed_grades_init" do
    build_file "ar003.0698", nil, :packed
    build_file "ar003.0701", nil, :cataloged
    build_file "fass/script/tape.ar004.0642_19770224", nil, :decoded
    build_file "fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229", nil, :baked
  end
end