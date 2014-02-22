#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/string'

no_tasks do
  def _exec(command, options={})
    $stderr.puts command unless options[:quiet]
    unless system(command)
      stop "!Command failed with code #{$?}"
    end
  end

  def copy_file(from, to, options={})
    orig_from = from
    from = File.expand_path(from)
    to = File.expand_path(to)
    from += '.txt' unless File.exists?(from)
    stop "!Source file #{orig_from.safe} does not exist" unless File.exists?(from)
    cmd = "mkdir -p #{File.dirname(to).safe}"
    _exec cmd, options
    cmd = "cp -f #{from.safe} #{to.safe}"
    _exec cmd, options
  end
  
  def build_file(file, at=nil, format=:cataloged, options={})
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
    file_with_extension = file
    file_with_extension += extension unless File.nondate_extname(file_with_extension) == extension
    source_file = File.join(File.expand_path(from),file_with_extension)
    source_file += '.txt' unless File.exists?(source_file)
    target_file = File.join(File.expand_path(at),file_with_extension)
    copy_file(source_file, target_file, quiet: options[:quiet])
  end
  
  def build_directory(at, options={}, &blk)
    _exec "rm -rf #{at.safe}", options
    _exec "mkdir -p #{at.safe}", options
    $at = at
    yield(at) if block_given?
  end
  
  def build_small_directory(at, format=:cataloged, options={})
    build_directory(at, options) do
      build_file "ar003.0698", nil, format, quiet: options[:quiet]
      build_file "ar054.2299", nil, format, quiet: options[:quiet]
    end
  end
  
  def build_standard_directory(at, format=:cataloged, options={})
    build_directory(at, options) do
      build_file "ar003.0698", nil, format, quiet: options[:quiet]
      build_file "ar003.0701", nil, format, quiet: options[:quiet]
      build_file "ar082.0605", nil, format, quiet: options[:quiet]
      build_file "ar083.0698", nil, format, quiet: options[:quiet]
      build_file "ar103.1065", nil, format, quiet: options[:quiet]
      build_file "ar126.0527", nil, format, quiet: options[:quiet]
    end
  end
  
  def build_general_test(at, format=:cataloged, options={})
    build_directory(at, options) do
      build_file "ar003.0698", nil, format, quiet: options[:quiet]
      build_file "ar003.0701", nil, format, quiet: options[:quiet]
      build_file "ar004.0888", nil, format, quiet: options[:quiet]
      build_file "ar019.0175", nil, format, quiet: options[:quiet]
      build_file "ar025.0634", nil, format, quiet: options[:quiet]
      build_file "ar082.0605", nil, format, quiet: options[:quiet]
      build_file "ar083.0698", nil, format, quiet: options[:quiet]
      build_file "ar145.2699", nil, format, quiet: options[:quiet]
    end
  end

  def build_compress_test_directory(at, options={})
    build_directory(at, options) do
      # These two files are identical
      build_file "bjeroehl/fass/bjthings_19781219_151907/addinde/tape.ar082.0604_19780620_175438", nil, :decoded, quiet: options[:quiet]
      build_file "fass/bjeroehl/bjthings_19781219_151907/addinde/tape.ar020.1140_19780620_175438", nil, :decoded, quiet: options[:quiet]
      # These two files are identical
      build_file "bjeroehl/fass/bjthings_19781219_151907/rjbmail/tape.ar082.0604_19780725_174329", nil, :decoded, quiet: options[:quiet]
      build_file "fass/bjeroehl/bjthings_19781219_151907/rjbmail/tape.ar020.1140_19780725_174329", nil, :decoded, quiet: options[:quiet]
      # This file isn't identical to anything else
      build_file "bjeroehl/fass/bjthings_19781219_151907/countess/tape.ar082.0604_19780630_182833", nil, :decoded, quiet: options[:quiet]
      # These four files are identical
      build_file "fass/one/zero/tape.ar003.2557_19770118", nil, :decoded, quiet: options[:quiet]
      build_file "fass/one/zero/tape.ar004.0495_19770210", nil, :decoded, quiet: options[:quiet]
      build_file "bjeroehl/fass/77script.f_19770301_154058/1zero/tape.ar082.0603_19770210_164752", nil, :decoded, quiet: options[:quiet]
      build_file "fass/scripfrz_19770301_154058/1zero/tape.ar004.0888_19770210_164752", nil, :decoded, quiet: options[:quiet]
    end
  end
end

desc "build", "Build test files"
option "quiet",    :aliases=>'-q', :type=>'boolean',  :desc=>"Quiet mode"
def build
  # TODO This could use some serious refactoring to avoid all the quiet: options[:quiet] stuff
  build_file "ar003.0698", "data/test_init", :cataloged, quiet: options[:quiet]
  build_file "ar004.0642", "data/test_init", :cataloged, quiet: options[:quiet]
  build_file "ar019.0175", "data/test_init", :cataloged, quiet: options[:quiet]
  build_file "ar119.1801", "data/test_init", :cataloged, quiet: options[:quiet]
  build_file "ar047.1383", "data/test_init", :cataloged, quiet: options[:quiet]
  build_file "ar074.1174", "data/test_init", :cataloged, quiet: options[:quiet]

  _exec "rm -rf data/test", quiet: options[:quiet]
  _exec "cp -rf data/test_init data/test", quiet: options[:quiet]
    
  build_standard_directory "data/test/archive/catalog_source_init", :unpacked, quiet: options[:quiet]
  
  build_directory("data/test/archive/packed_with_bad_files_init", quiet: options[:quiet]) do
    _exec("cp data/test_init/packed_with_bad* data/test/archive/packed_with_bad_files_init", quiet: options[:quiet])
    _exec("cp data/test_init/ar003.0698 data/test/archive/packed_with_bad_files_init", quiet: options[:quiet])
  end

  build_directory("data/test/archive/roff/fass/1990", quiet: options[:quiet]) do
    _exec "cp -r #{ENV['HOME']}/fass_work/baked/fass/1990/script data/test/archive/roff/fass/1990/script", quiet: options[:quiet]
  end
  
  build_directory("data/test/archive/compact_source_init", quiet: options[:quiet]) do
    build_file "ar004.0888", nil, :cataloged, quiet: options[:quiet]
    build_file "ar009.2622", nil, :cataloged, quiet: options[:quiet]
    build_file "ar010.0006", nil, :cataloged, quiet: options[:quiet]
    build_file "ar013.0560", nil, :cataloged, quiet: options[:quiet]
    build_file "ar019.0175", nil, :cataloged, quiet: options[:quiet]
    build_file "ar019.1842", nil, :cataloged, quiet: options[:quiet]
    build_file "ar077.0633", nil, :cataloged, quiet: options[:quiet]
    build_file "ar103.1065", nil, :cataloged, quiet: options[:quiet]
    build_file "ar108.2439", nil, :cataloged, quiet: options[:quiet]
    build_file "ar114.1860", nil, :cataloged, quiet: options[:quiet]
    build_file "ar116.1647", nil, :cataloged, quiet: options[:quiet]
    build_file "ar119.1124", nil, :cataloged, quiet: options[:quiet]
    build_file "ar126.0345", nil, :cataloged, quiet: options[:quiet]
  end
  
  build_small_directory "data/test/archive/contents", :cataloged, quiet: options[:quiet]
  build_small_directory "data/test/archive/contents_packed", :packed, quiet: options[:quiet]
  build_small_directory "data/test/archive/decode_existing_init", :cataloged, quiet: options[:quiet]

  build_standard_directory "data/test/archive/decode_source_init", :cataloged, quiet: options[:quiet]
  
  build_general_test "data/test/archive/general_test", :cataloged, quiet: options[:quiet]
  build_general_test "data/test/archive/general_test_packed_init", :packed, quiet: options[:quiet]

  build_directory("data/test/archive/packed_with_subdirectories", quiet: options[:quiet])
  build_directory("data/test/archive/packed_with_subdirectories/ar003", quiet: options[:quiet]) do
    build_file "ar003.0698", nil, :packed, quiet: options[:quiet]
  end
  build_directory("data/test/archive/packed_with_subdirectories/foo/bar", quiet: options[:quiet]) do
    build_file "ar019.0175", nil, :packed, quiet: options[:quiet]
  end

  _exec "cp -r data/test/archive/packed_with_bad_files_init data/test/archive/packed_with_bad_files",
    quiet: options[:quiet]

  build_directory("data/test/archive/init", quiet: options[:quiet]) do
    build_file "ar003.0698", nil, :packed, quiet: options[:quiet]
  end

  build_standard_directory "data/test/archive/mv_init", :cataloged, quiet: options[:quiet]
  build_standard_directory "data/test/archive/mv_init/directory", :cataloged, quiet: options[:quiet]
  build_standard_directory "data/test/archive/rm_init", :cataloged, quiet: options[:quiet]
  build_standard_directory "data/test/archive/rv_init/directory", :cataloged, quiet: options[:quiet]

  # Build mixed directory
  build_directory("data/test/archive/mixed_formats_init", quiet: options[:quiet]) do
    build_file "ar003.0698", nil, :packed, quiet: options[:quiet]
    build_file "ar003.0701", nil, :cataloged, quiet: options[:quiet]
    build_file "fass/script/tape.ar004.0642_19770224", nil, :decoded, quiet: options[:quiet]
    copy_file "~/fass_work/baked/fass/1986/script/script.f/1-1", 
              "data/test/archive/mixed_formats_init/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229",
              quiet: options[:quiet]
  end

  build_compress_test_directory "data/test/archive/compress_init", quiet: options[:quiet]
  build_compress_test_directory "data/test/archive/same", quiet: options[:quiet]

  # Build compress conflict test
  build_directory("data/test/archive/compress_conflict_init", quiet: options[:quiet]) do |dir|
    _exec "cp -rf data/test_init/compress_conflict #{at.safe}"
  end
end