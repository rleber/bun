#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

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
        title:   "type for executable file", 
        command: "show type data/test/ar010.1307"
      },
      {
        title:   "executable for normal file", 
        command: "show executable data/test/ar003.0698.bun"
      },
      {
        title:   "executable for executable file", 
        command: "show executable data/test/ar010.1307"
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
