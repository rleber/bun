#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

WORD_FORMAT = '%012o'
DEFAULT_FORMAT = '%p'
TEST_WIDTH = 36
TEST_WORD_SLICES = %w{half_word byte character packed_character bit integer}
STRING_SLICES = %w{character packed_character}
NON_STRING_SLICES = TEST_WORD_SLICES - STRING_SLICES
SIGNED_SLICES = %w{integer}
TEST_WORD_SLICE_CLASSES = TEST_WORD_SLICES.inject({}) do |hsh, slice_name|
  hsh[slice_name.to_sym] = slice_name.gsub(/(^|_)(.)/) {|match| $2.upcase}
  hsh
end
FORMATS = %w{default inspect octal decimal binary hex}
STRING_FORMATS = FORMATS + %w{string string_inspect}

SLICE_COUNTS = {:byte=>4, :character=>4, :packed_character=>5, :half_word=>2, :bit=>TEST_WIDTH, :integer=>1}
SLICE_TEST_WIDTHS = {:byte=>9, :character=>9, :packed_character=>7, :half_word=>18, :bit=>1, :integer=>TEST_WIDTH}
SLICE_BITS   = {:byte=>9, :character=>7, :packed_character=>7, :half_word=>18, :bit=>1, :integer=>TEST_WIDTH}
SLICE_STRING = TEST_WORD_SLICES.inject({}) do |hsh, slice_name|
  hsh[slice_name.to_sym] = !!STRING_SLICES.include?(slice_name)
  hsh
end
SLICE_SIGN  = TEST_WORD_SLICES.inject({}) do |hsh, slice_name|
  hsh[slice_name.to_sym] = !!SIGNED_SLICES.include?(slice_name)
  hsh
end

$bytes = TestWord.new(0111222333444)
BYTE_ASC_VALUES = {
  :character=>[0111, 022, 0133, 044],
  :packed_character=>[0b0100100,0b1010010,0b0100110,0b1101110,0b0100100],
}
BYTE_VALUES = {
  :byte=>[0111, 0222, 0333, 0444],
  :character=>BYTE_ASC_VALUES[:character].map{|v| v.chr},
  :packed_character=>BYTE_ASC_VALUES[:packed_character].map{|v| v.chr},
  :half_word=>[0111222, 0333444],
  :bit=>[0,0,1,0,0,1,0,0,1,0,1,0,0,1,0,0,1,0,0,1,1,0,1,1,0,1,1,1,0,0,1,0,0,1,0,0],
  :integer=>[0111222333444],
}
if RUBY_VERSION =~ /^1\.8/
  $strings = TestWord.new([?A,?B,?C,?D].inject(0) {|value, ch| value<<9 | ch })
else
  $strings = TestWord.new([?A,?B,?C,?D].inject(0) {|value, ch| value<<9 | ch.getbyte(0) })
end
$positive = TestWord.new(1)
$negative = TestWord.new(eval('0b' + '1'*TEST_WIDTH))
$negative_twos = $negative
$negative_ones = TestWordOnes.new(eval('0b' + ('1'*(TEST_WIDTH-1)) + '0'))
$words = TestWords[1,2,3]

def is_numeric?(v)
  v.is_a?(Numeric) || v.is_a?(GenericNumeric)
end

shared_examples "with width" do |object, width|
  width ||= TEST_WIDTH
  it "should define correct width" do
    object.width.should == width
  end
end

shared_examples "with slices" do |object|
  it "should define slices" do
    expect { object.slices }.should_not raise_error
  end
  
  context "slices" do
    it "should be a Hash" do
      object.slices.should be_a_kind_of Hash
    end
    
    it "should contain Slice::Definitions" do
      all_defns = true
      object.slices.each do |key, defn|
        all_defns &&= defn.should be_a_kind_of Slicr::Slice::Definition
      end
      all_defns.should be_true
    end
  end
end

shared_examples "a segment" do ||
  include_examples "with width", $parent, $width
  include_examples "with slices", $parent
end

shared_examples "slice method" do |slice_name|
  it "should define <parent>.#{slice_name}" do
    $parent.should respond_to slice_name
  end
end

shared_examples "slice definition" do |slice_name|
  slice_name = slice_name.to_sym
  slice_object = $parent.send(slice_name) rescue nil
  it "sets .count" do
    slice_object.count.should == SLICE_COUNTS[slice_name]
  end

  it "sets .width" do
    slice_object.width.should == SLICE_TEST_WIDTHS[slice_name]
  end

  it "sets .significant_bits" do
    slice_object.bits.should == SLICE_BITS[slice_name]
  end

  it "sets .string?" do
    slice_object.string?.should == SLICE_STRING[slice_name]
  end

  it "sets .sign?" do
    slice_object.sign?.should == SLICE_SIGN[slice_name]
  end
end

shared_examples "slice class" do |slice_name|
  slice_class_name = TEST_WORD_SLICE_CLASSES[slice_name.to_sym]
  slice_class = TestWord.const_get(slice_class_name) rescue nil
  
  context "#{slice_class_name} class" do
    it "exists" do
      slice_class.should be_a_kind_of Class
    end
    
    it "defines .formats" do
      slice_class.should respond_to :formats
    end

    it "defines .string?" do
      slice_class.should respond_to :string?
    end
  end
end

# Spot check only -- the thorough checking is in indexable_basic_spec.rb
shared_examples "slicr is indexed" do |object, expected_values|
  size = expected_values.size
  
  it "should allow indexing" do
    object.should respond_to :[]
  end
  
  it "should return nil for self[-(size+1)]" do
    object[-(size+1)].should be_nil
  end
  
  it "should return nil for self[size]" do
    object[size].should be_nil
  end
  
  size.times do |i|
    it "should retrieve self[#{i}]" do
      object[i].should == expected_values[i]
    end
  end
  
  size.times do |i|
    it "should retrieve self[#{i-size}]" do
      object[i-size].should == expected_values[i]
    end
  end
  
  [false, true].each do |negative_i|
    [false, true].each do |negative_j|
      [-(size+1), -(size.div(2)), 2, size.div(2), size-1, size+1].each do |i|
        next if (negative_i && i >= 0) || (!negative_i && i<0)
        [-(size+1), -(size.div(2)), 2, size.div(2), size-1, size+1].each do |j|
          next if (negative_j && j >= 0) || (!negative_j && j<0)
          it "should retrieve self[#{i}..#{j}]" do
            object[i..j].should == expected_values[i..j]
          end
        end
      end
  
      [-(size+1), -(size.div(2)), 2, size.div(2), size-1, size+1].each do |i|
        next if (negative_i && i >= 0) || (!negative_i && i<0)
        [-(size+1), -(size.div(2)), 2, size.div(2), size-1, size+1].each do |j|
          next if (negative_j && j >= 0) || (!negative_j && j<0)
          it "should retrieve self[#{i}...#{j}]" do
            object[i...j].should == expected_values[i...j]
          end
        end
      end
    end
  end
  
  [false, true].each do |negative_i|
    [-(size+1), -(size.div(2)), 2, size.div(2), size-1, size+1].each do |i|
      next if (negative_i && i >= 0) || (!negative_i && i<0)
      [-1, size.div(2), (size+1)].each do |l|
        it "should retrieve self[#{i},#{l}]" do
          object[i,l].should == expected_values[i,l]
        end
      end
    end
  end
end

shared_examples "it is sliced" do
  TEST_WORD_SLICES.each do |slice_name|
    context slice_name do
      include_examples "slice method", slice_name
      include_examples "slice definition", slice_name
      include_examples "slice class", slice_name
    end
  end
end

describe Slicr::Word do
  it "should define String#pluralize" do
    "abcdef".should respond_to :pluralize
  end
end

describe "word" do
  $parent = TestWord
  $width = TEST_WIDTH
  it_behaves_like "a segment"
  it_behaves_like "it is sliced"
end
  
describe "instance" do
  $parent = $bytes
  $width = nil

  context "automatically installs formats" do
    it "understands formats" do
      expect { $bytes.integer(0).unsigned.octal }.should_not raise_error
    end
  end

  it_behaves_like "a segment"
  it_behaves_like "it is sliced"
  
  TEST_WORD_SLICES.each do |slice_name|
    defn = $parent.class.slices[slice_name]
    slices_name = slice_name.pluralize
    slice_class_name = TEST_WORD_SLICE_CLASSES[slice_name.to_sym]
    slice_object = $bytes.send(slice_name) rescue nil
    slice_count = slice_object.count

    context slice_name do
      it_behaves_like "slicr is indexed", slice_object, BYTE_VALUES[slice_name.to_sym]
      
      $bytes.send(slice_name).count.times do |i|
        context "#{slice_name}[#{i}]" do
          slice = $bytes.send(slice_name)[i]
          
          it "should define the .format method" do
            slice.should respond_to :format
          end

          it "the .format method should use the default format" do
            slice.format.should == slice.format(:default)
          end

          it "should define the .value method" do
            slice.should respond_to :value
          end
        end
      end
      
      it "should allow access to all the slices by .#{slices_name}" do
        $bytes.should respond_to slices_name
      end

      context ".#{slices_name}" do
        before do
          @slices = $bytes.send(slices_name)
        end
        
        it "should be an Array" do
          @slices.should be_a_kind_of Array
        end
        
        it "should contain the expected number of elements" do
          @slices.size.should == SLICE_COUNTS[slice_name.to_sym]
        end
      
        it "should contain instances of the proper slice class (#{slice_class_name})" do
          @slices.inject(true) {|value, slice| value && slice.is_a?(TestWord.const_get(slice_class_name)) }.should == true
        end
      end
    end
  end

  context "slices" do
    context "with significant_bits < width" do
      it "should mask out non-significant bits" do
        $bytes.character[2].asc.should == 0133
      end
    end
  
    context "slices with width > underlying data width" do
      it "should have 0 count" do
        StrangeWord.too_long.count.should == 0
      end
    end
    
    STRING_SLICES.each do |slice_name|
      slice = $bytes.send(slice_name) rescue nil
      slices_name = slice_name.pluralize
      
      context "string slice #{slice_name}" do
        it "should define all string formats" do
          slice.formats.keys.map{|f| f.to_s}.sort.should == STRING_FORMATS.sort
        end
        
        it "should return true for .string?" do
          slice.string?.should == true
        end
        
        slice.count.times do |i|
          context "[#{i}]" do
            slice_object = slice[i]
            
            # it "should create a .string" do
            #   slice_object.should respond_to :string
            # end

            # it " .to_s should == .string" do
            #   slice_object.to_s.should == slice_object.string
            # end

            slice.formats.keys.each do |fmt|
              context "format #{fmt}" do
                it "should display .format(#{fmt})" do
                  expect { slice_object.format(fmt) }.should_not raise_error
                end

                if fmt == :default
                  it " .format(#{fmt.inspect}) should == .string_inspect" do
                    slice_object.format(:default).should == slice_object.string_inspect
                  end

                  it " .format should == .format(#{fmt.inspect})" do
                    slice_object.format(:default).should == slice_object.string_inspect
                  end
                else
                  it " .#{fmt} should == .format(#{fmt})" do
                    slice_object.send(fmt).should == slice_object.format(fmt)
                  end
                end
              end
            end

            it "should define the .asc method" do
              is_numeric?(slice_object.asc).should be true
            end
    
            it "should define the .plus method" do
              slice_object.plus(2).should == (slice_object.asc + 2)
            end
    
            it "should have .asc >= 0" do
              slice_object.asc.should be >= 0
            end
            
            it "should allow .asc.format" do
              expect { slice_object.asc.format }.should_not raise_error
            end
    
            it "should return a string as .value" do
              slice_object.value.should be_a_kind_of String
            end
    
            it "should have .value == .asc.chr" do
              slice_object.value.should == slice_object.asc.chr
            end
    
            it "should define the + operator as concatenation" do
              (slice_object + "a").should == (slice_object.value + "a")
            end
    
            it "should allow prefix +" do
              expect { "a" + slice_object }.should_not raise_error
            end
    
            it "should allow postfix +" do
              expect { slice_object + "a" }.should_not raise_error
            end
    
            it "should not define .sign?" do
              expect { slice_object.sign? }.should raise_error
            end
          end
        end
      end
      
      it ".<slices_name> should create a merged string using .join" do
        $strings.characters.join.should == "ABCD"
      end
    end
    
    NON_STRING_SLICES.each do |slice_name|
      slice = $bytes.send(slice_name) rescue nil
      slices_name = slice_name.pluralize

      context "non-string slice #{slice_name}" do
        it "should return false for .string?" do
          (!!slice.string?).should == false
        end
    
        it "should define all relevant formats" do
          slice.formats.keys.map{|f| f.to_s}.sort.should == FORMATS.sort
        end
        
        it "should define .sign?" do
          expect { slice.sign? }.should_not raise_error
        end

        slice.count.times do |i|
          context "[#{i}]" do
            slice_object = slice[i]

            it "should not define the .asc method" do
              expect {slice_object.asc }.should raise_error
            end

            # it "should not define the string format" do
            #   expect {slice_object.string }.should raise_error
            # end
    
            it "should not define the string_inspect format" do
              expect {slice_object.string_inspect }.should raise_error
            end

            it " .to_s should == default format" do
              slice_object.to_s.should == slice_object.format
            end

            slice.formats.keys.each do |fmt|
              context "format #{fmt}" do
                it "should display .format(#{fmt})" do
                  expect { slice_object.format(fmt) }.should_not raise_error
                end

                if fmt == :default
                  it " .format should == .format(#{fmt.inspect})" do
                    slice_object.format.should == slice_object.format(:default)
                  end
                else
                  it " .#{fmt} should == .format(#{fmt})" do
                    slice_object.send(fmt).should == slice_object.format(fmt)
                  end
                end
              end
            end

            it "should not define the .plus method" do
              expect {slice_object.plus(2) }.should raise_error
            end
    
            it "should return a number as .value" do
              slice_object.value.should be_a_kind_of Numeric
            end
            
            it "should return the proper value" do
              slice_object.value.should == BYTE_VALUES[slice_name.to_sym][i]
            end
    
            it "should define the + operator as addition" do
              (slice_object + 2).value.should == (slice_object.value + 2)
            end

            it "should allow prefix arithmetic" do
              expect { 2 + slice_object }.should_not raise_error
            end

            it "should allow postfix arithmetic" do
              expect { slice_object + 2 }.should_not raise_error
            end

            # it "should not create a merged string using .#{slices_name}.string" do
            #   expect { slice_object.send(slices_name).string }.should raise_error
            # end
            
            # TODO slice_object.sign? should be possible
            if slice.sign?
              context "with signs" do
                it "the default format should be decimal" do
                  slice_object.format.should == slice_object.format(:decimal)
                end

                it "should define the .signed method" do
                  slice_object.should respond_to :signed
                end
                  
                it "should have value == signed" do
                  slice_object.value.should == slice_object.signed
                end

                it "should define the .unsigned method" do
                  slice_object.should respond_to :unsigned
                end

                it "should allow .signed.format" do
                  slice_object.signed.should respond_to :format
                end

                it "should allow .unsigned.format" do
                  slice_object.unsigned.should respond_to :format
                end
                
                it "should allow .unsigned.octal" do
                  slice_object.unsigned.should respond_to :octal
                end
      
                it "should have .unsigned >= 0" do
                  slice_object.unsigned.should be >= 0
                end
                
              end
            else
              context "without signs" do
                it "the default format should be octal" do
                  slice_object.format.should == slice_object.format(:octal)
                end
    
                it "should not define .signed" do
                  expect { slice_object.signed }.should raise_error
                end
    
                it "should not define .unsigned" do
                  expect { slice_object.unsigned }.should raise_error
                end
              end
            end
          end
        end
      end
    end
  end

  context "with positive values" do
    it "should have .signed == .unsigned" do
      $positive.integer.signed.should == $positive.integer.unsigned
    end
  end

  context "with negative values" do
    it "should have .signed < 0" do
      $negative.integer.signed.should be < 0
    end
    
    it "should handle negative math okay" do
      ($negative_twos.integer.value * $negative_ones.integer.value).should == 1
    end

    context "in two's complement format" do
      it "should have .signed set properly" do
        $negative_twos.integer.signed.should == -1
      end

      it "should have .unsigned set properly" do
        $negative_twos.integer.unsigned.should == eval('0b' + '1'*TEST_WIDTH)
      end

      it "should handle -(-1) properly" do
        (-($negative_twos.integer.value)).should == 1
      end
      
    end

    context "in one's complement format" do
      it "should have .signed set properly" do
        $negative_ones.integer.signed.should == -1
      end

      it "should have .unsigned set properly" do
        $negative_ones.integer.unsigned.should == eval('0b' + '1'*(TEST_WIDTH-1) + '0')
      end
    end
  end
  
  context "any slice" do
    it "should default to .value" do
      ($bytes.byte[1] + 2).should == (0222 + 2)
    end
  end
  
  context "any field" do
    it "should collapse" do
      ($positive.integer.signed).should == $positive.integer[0]
    end
    
    it "should default to .value" do
      ($positive.integer + 2).should == 3
    end
  end
end

describe Slicr::WordsBase do
  it "should set size" do
    $words.size.should == 3
  end
  
  it_behaves_like "slicr is indexed", $words, [1,2,3]
  
  it "should allow accessors" do
    $words.bytes.to_a.should == [0,0,0,1,0,0,0,2,0,0,0,3]
  end
  
  it "should allow indexed accessors" do
    $words[1,2].half_words.to_a.should == [0,2,0,3]
  end
end
# TODO Write tests for Blocks
# $double_word = Bun::Block[1,2]
# show_value "$double_word"
# show_value "$double_word[0]"
# show_value "$double_word[0].class"
# show_value "$double_word[1].to_s"
# show_value "$double_word.word_and_a_halfs"