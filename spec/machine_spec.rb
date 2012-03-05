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

$strings = TestWord.new([?A,?B,?C,?D].inject{|value, ch| value<<9 | ch })
$positive = TestWord.new(1)
$negative = TestWord.new(eval('0b' + '1'*TEST_WIDTH))
$negative_twos = $negative
$negative_ones = TestWordOnes.new(eval('0b' + ('1'*(TEST_WIDTH-1)) + '0'))
$words = TestWords[1,2,3]

def is_numeric?(v)
  v.is_a?(Numeric) || v.is_a?(GenericNumeric)
end

describe Machine::Word do
  
  it "should define String#pluralize" do
    "abcdef".should respond_to :pluralize
  end

  context "subclass" do
    it "should define width method for the Word class" do
      TestWord.width.should == TEST_WIDTH
    end
    
    # TODO Refactor using shared_examples, custom matchers, etc.
  
    it "should define ones_mask" do
      # ones_mask should be 0b11111...
      ('%b' % TestWord.ones_mask).should match /^1{#{TEST_WIDTH}}$/
    end
    
    (0..(TEST_WIDTH+1)).each do |bit|
      context "for bit number #{bit}" do
        it "should define single_bit mask" do
          # single_bit_mask should be 0b100000...
          ('%b' % TestWord.single_bit_mask(bit)).should match /^10{#{bit}}$/
        end
      end
    end
    
    it "should define slices" do
      expect { TestWord.slices }.should_not raise_error
    end
    
    context "slices" do
      it "should be a Hash" do
        TestWord.slices.should be_a_kind_of Hash
      end
      
      it "should contain Slice::Definitions" do
        all_defns = true
        TestWord.slices.each do |key, defn|
          all_defns &&= defn.should be_a_kind_of Machine::Slice::Definition
        end
        all_defns.should be_true
      end
    end
    
    TestWord.slices.each do |slice_name, defn|
      it "should define .#{slice_name}" do
        TestWord.should respond_to slice_name
      end

      context slice_name do
        slices_name = slice_name.pluralize
        slice_object = TestWord.send(slice_name) rescue nil

        it "should define .count" do
          expect { slice_object.count }.should_not raise_error
        end

        it "should count #{slices_name} correctly" do
          slice_object.count.should == SLICE_COUNTS[slice_name.to_sym]
        end

        it "should define the .width method" do
          slice_object.width.should == SLICE_TEST_WIDTHS[slice_name.to_sym]
        end

        it "should define the .significant_bits method" do
          slice_object.bits.should == SLICE_BITS[slice_name.to_sym]
        end

        it "should define the .string? method" do
          slice_object.string?.should == SLICE_STRING[slice_name.to_sym]
        end

        it "should define the .sign? method" do
          slice_object.sign?.should == SLICE_SIGN[slice_name.to_sym]
        end

        it "should define the .mask method" do
          ('%b' % slice_object.mask).should match /^1{#{SLICE_BITS[slice_name.to_sym]}}$/
        end
      end
    end
  end
  
  context "instances" do
    it "should define width method" do
      $bytes.width.should == TestWord.width
    end

    (0..(TEST_WIDTH+1)).each do |bit|
      context "for bit number #{bit}" do
        it "should define ones_mask" do
          # ones_mask should be 0b11111...
          if bit==0
            $bytes.ones_mask(bit).should == 0
          else
            ('%b' % $bytes.ones_mask(bit)).should match /^1{#{bit}}$/
          end
        end

        it "should define single_bit_mask" do
          # single_bit_mask should be 0b100000...
          ('%b' % $bytes.single_bit_mask(bit)).should match /^10{#{bit}}$/
        end
      end
    end
    
    it "should define slices" do
      expect { $bytes.slices }.should_not raise_error
    end
    
    context "slices" do
      it "should be a Hash" do
        $bytes.slices.should be_a_kind_of Hash
      end
      
      it "should contain Slice::Definitions" do
        all_defns = true
        $bytes.slices.each do |key, defn|
          all_defns &&= defn.should be_a_kind_of Machine::Slice::Definition
        end
        all_defns.should be_true
      end
    end
    
    TestWord.slices.each do |slice_name, defn|
      slices_name = slice_name.pluralize
      slice_class_name = TEST_WORD_SLICE_CLASSES[slice_name.to_sym]
      slice_object = $bytes.send(slice_name) rescue nil

      it "should define .#{slice_name}" do
        $bytes.should respond_to slice_name
      end
      
      context "#{slice_class_name} class" do
        slice_class = TestWord.const_get(slice_class_name) rescue nil

        it "should define the #{slice_class_name} class" do
          slice_class.should be_a_kind_of Class
        end
        
        it "should define .formats" do
          slice_class.should respond_to :formats
        end

        it "should define <slice_class>.string?" do
          slice_class.should respond_to :string?
        end
      end

      context slice_name do
        it "should define .count" do
          expect { slice_object.count }.should_not raise_error
        end
      
        it "should count #{slices_name} correctly" do
          slice_object.count.should == SLICE_COUNTS[slice_name.to_sym]
        end

        it "should define the .width method" do
          slice_object.width.should == SLICE_TEST_WIDTHS[slice_name.to_sym]
        end

        it "should define the .significant_bits method" do
          slice_object.bits.should == SLICE_BITS[slice_name.to_sym]
        end

        it "should define the .string? method" do
          slice_object.string?.should == SLICE_STRING[slice_name.to_sym]
        end

        it "should define the .sign? method" do
          slice_object.sign?.should == SLICE_SIGN[slice_name.to_sym]
        end

        it "should define the .mask method" do
          ('%b' % slice_object.mask).should match /^1{#{SLICE_BITS[slice_name.to_sym]}}$/
        end
        
        it "should return nil for #{slice_name}[#{-($bytes.send(slice_name).count+1)}]" do
          slice_object = $bytes.send(slice_name)
          slice_count = slice_object.count
          slice_object[-(slice_count+1)].should be_nil
        end
        
        it "should return nil for #{slice_name}[#{$bytes.send(slice_name).count}]" do
          slice_object = $bytes.send(slice_name)
          slice_count = slice_object.count
          slice_object[slice_count].should be_nil
        end
        
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
            
            it "should return the proper .value" do
              slice.value.should == BYTE_VALUES[slice_name.to_sym][i]
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
              
              it "should create a .string" do
                slice_object.should respond_to :string
              end

              it "the default format should be string_inspect" do
                slice_object.format.should == slice_object.string_inspect
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
                slice_object.string.should be_a_kind_of String
              end
      
              it "should have .string == .asc.chr" do
                slice_object.string.should == slice_object.asc.chr
              end
      
              it "should define the + operator as concatenation" do
                (slice_object + "a").should == (slice_object.string + "a")
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
        
        it ".<slices_name> should create a merged string using .string" do
          $strings.characters.string.should == "ABCD"
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

              it "should not define the string format" do
                expect {slice_object.string }.should raise_error
              end
      
              it "should not define the string_inspect format" do
                expect {slice_object.string_inspect }.should raise_error
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

              it "should not create a merged string using .#{slices_name}.string" do
                expect { slice_object.send(slices_name).string }.should raise_error
              end
              
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
end

describe Machine::WordsBase do
  it "should set size" do
    $words.size.should == 3
  end
  
  it "should allow indexing" do
    $words[0].should == 1
  end
  
  it "should allow negative indexing" do
    $words[-1].should == 3
  end
  
  it "should allow inclusive index ranges" do
    $words[1..2].should == [2,3]
  end
  
  it "should allow exclusive index ranges" do
    $words[1...-1].should == [2]
  end
  
  it "should allow indexing by pairs" do
    $words[1,2].should == [2,3]
  end
  
  it "should allow assignment" do
    words = $words.dup
    words[4] = 4
    words.should == [1,2,3,nil,4]
  end
  
  it "should allow accessors" do
    $words.bytes.should == [0,0,0,1,0,0,0,2,0,0,0,3]
  end
  
  it "should allow indexed accessors" do
    $words[1,2].half_words.should == [0,2,0,3]
  end
end

# TODO Write tests for Blocks
# $double_word = GECOS::Block[1,2]
# show_value "$double_word"
# show_value "$double_word[0]"
# show_value "$double_word[0].class"
# show_value "$double_word[1].to_s"
# show_value "$double_word.word_and_a_halfs"
