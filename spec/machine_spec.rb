require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

WORD_FORMAT = '%012o'
DEFAULT_FORMAT = '%p'
WIDTH = 36
TEST_WORD_SLICES = ["half_word", "byte", "character", "packed_character", "bit", "integer"]
TEST_WORD_SLICE_CLASSES = TEST_WORD_SLICES.inject({}) {|hsh, slice_name| hsh[slice_name] = slice_name.gsub(/(^|_)(.)/) {|match| $2.upcase}; hsh}

describe Machine::Word do
  
  it "should define String#pluralize" do
    "abcdef".should respond_to :pluralize
  end

  context "the Word subclass" do
    it "should define width method for the Word class" do
      TestWord.width.should == WIDTH
    end
  
    it "should define ones_mask" do
      # ones_mask should be 0b11111...
      ('%b' % TestWord.ones_mask).should match /^1{#{WIDTH}}$/
    end
    
    context "for positive bit numbers, up to and past WIDTH" do
      (0..(WIDTH+1)).each do |bit|
        it "should define single_bit mask(#{bit})" do
          # single_bit_mask should be 0b100000...
          ('%b' % TestWord.single_bit_mask(bit)).should match /^10{#{bit}}$/
        end
      end
    end
    
    it "should define slice_names" do
      TestWord.slice_names.sort.should == TEST_WORD_SLICES.sort
    end
    
    context "for all slices" do
      TestWord.slice_names.each do |slice_name|
        before do
          slices_name = slice_name.pluralize
        end
        
        it "should define slice_definition(#{slice_name.inspect})" do
          TestWord.slice_definition(slice_name).should be_a_kind_of Machine::Slice::Definition
        end
        
        it "should define .<slice_name> (#{slice_name})" do
          TestWord.should respond_to slice_name
        end

        # it "should define .<slices>_per_word (#{slices_name})" do
        #   TestWord.should respond_to "#{slice_name}_count"
        # end
      end
    end
  end
  
  context "instances of the Word subclass" do
    before do
      @bytes = TestWord.new(0111222333444)
      @slice_counts = {:byte=>4, :character=>4, :packed_character=>5, :half_word=>2, :bit=>WIDTH, :integer=>1}
    end
    
    it "should define width method" do
      @bytes.width.should == TestWord.width
    end

    context "for positive bit numbers, up to and past WIDTH" do
      (0..(WIDTH+1)).each do |bit|
        it "should define ones_mask(#{bit})" do
          # ones_mask should be 0b11111...
          if bit==0
            @bytes.ones_mask(bit).should == 0
          else
            ('%b' % @bytes.ones_mask(bit)).should match /^1{#{bit}}$/
          end
        end

        it "should define single_bit_mask(#{bit})" do
          # single_bit_mask should be 0b100000...
          ('%b' % @bytes.single_bit_mask(bit)).should match /^10{#{bit}}$/
        end
      end
    end
    
    it "should define slice_names" do
      @bytes.slice_names.sort.should == TestWord.slice_names.sort
    end
    
    context "for all slices" do
      TestWord.slice_names.each do |slice_name|
        puts "slice_name = #{slice_name.inspect}"
        slices_name = slice_name.pluralize
        slice_class_name = TEST_WORD_SLICE_CLASSES[slice_name]
        
        it "should define slice_definition(#{slice_name.inspect})" do
          @bytes.slice_definition(slice_name).should be_a_kind_of Machine::Slice::Definition
        end
        
        it "should define .<slice_name> (#{slice_name})" do
          @bytes.should respond_to slice_name
        end
        
        it "should define the slice class (#{slice_class_name})" do
          TestWord.const_get(slice_class_name).should be_a_kind_of Class
        end
      
        it "should define .<slice>.count (#{slice_name})" do
          @bytes.send(slice_name).should respond_to :count
        end
        
        it "should count slices correctly (#{slice_name})" do
          @bytes.send(slice_name).count.should == @slice_counts[slice_name.to_sym]
        end
      
        it "should allow access to all the slices by .<slices_name> (#{slices_name})" do
          @bytes.should respond_to slices_name
        end
        
        context ".<slices_name (#{slices_name})" do
          before do
            @slices = @bytes.send(slices_name)
          end
          
          it "should be an Array" do
            @slices.should be_a_kind_of Array
          end
          
          it "should contain the expected number of elements" do
            @slices.size.should == @slice_counts[slice_name.to_sym]
          end
        
          it "should contain instances of the proper slice class (#{slice_class_name})" do
            @slices.inject(true) {|value, slice| value && slice.is_a?(TestWord.const_get(slice_class_name)) }.should == true
          end
        end
      end
    end
    
    it "should define <slice_class>.format_names" do
    end
  
    it "should define <slice_class>.format_definitions" do
    end
  
    it "should define the .<slice_name>.format(...) method" do
    end

    it "the .<slice_name>.format method should use the default format" do
    end
  
    it "should define all relevant formats" do
    end
  
    it "should display all relevant formats" do
    end
  
    it "should define <slice_class>.string?" do
    end
  
    context "slices" do
      it "should define the .width method" do
      end

      it "should define the .offset method" do
      end
    
      it "should define the .count method" do
      end
    
      it "should define the .significant_bits method" do
      end
    
      it "should define the .string? method" do
      end
    
      it "should define the .sign? method" do
      end
    
      it "should define the .value method" do
      end
    
      it "should define the .signed method" do
      end
    
      it "should define the .unsigned method" do
      end
    
      it "should allow .signed.format" do
      end
    
      it "should allow .unsigned.format" do
      end
    
      it "should define the .mask method" do
      end
    
      context "with significant_bits < width" do
        it "should mask out non-significant bits" do
        end
      end
    
      context "slices with width > underlying data width" do
        it "should have 0 count" do
        end
      end

      context "for string type slices" do
        it "should return true for .string?" do
        end
      
        it "should define the string_inspect format" do
        end
  
        it "should create a merged string using .<slices_name>.string" do
        end
  
        it "should create a .<slice_name>[n].string" do
        end

        it "the default format should be string_inspect" do
        end
      
        it "should define the .plus method" do
        end
      
        it "should define the .asc method" do
        end
      
        it "should have .asc >= 0" do
        end
      
        it "should allow .asc.format" do
        end
      
        it "should return a string as .value" do
        end
      
        it "should have .string == .asc.chr" do
        end
      
        it "should have .asc == .signed" do
        end
      
        it "should have .asc == .unsigned" do
        end
      
        it "should define the + operator as concatenation" do
        end
      
        it "should allow prefix +" do
        end
      
        it "should allow postfix +" do
        end
      
        it "should return false for .sign?" do
        end
      end

      context "for non-string type slices" do
        it "should return false for .string?" do
        end
      
        it "should allow .value.format" do
        end

        context "with signs" do
          it "the default format should be decimal" do
          end
        
          it "should have .unsigned >= 0" do
          end
        
          context "and positive values" do
            it "should have .signed == .unsigned" do
            end
          end
        
          context "and negative values" do
            it "should have .signed < 0" do
            end
          
            context "in two's complement format" do
              it "should have .unsigned set properly" do
              end
            
              it "should handle -(-1) properly" do
              end
            end
          
            context "in one's complement format" do
              it "should have .unsigned set properly" do
              end
            end
          end
        end

        context "without signs" do
          it "the default format should be octal" do
          end
        
          it "should have .signed >= 0" do
          end
        
          it "should have .unsigned == .signed" do
          end
        end
      
        it "should not define the .asc method" do
        end
      
        it "should not define the string_inspect format" do
        end
  
        it "should not create a merged string using .<slices_name>.string" do
        end
  
        it "should not create a .<slice_name>[n].string" do
        end

        it "should not define the .plus method" do
        end
      
        it "should return a number as .value" do
        end
      
        it "should define the + operator as addition" do
        end
      end
    
      it "should allow prefix arithmetic" do
      end
    
      it "should allow postfix arithmetic" do
      end
    end
  end
end
# 
# $words = TestWords[1,2,3]
# show_value "$words.size"
# show_value "$words[0]"
# show_value "$words[0].class"
# $words[5] = 1234
# show_value "$words"
# show_value "$words[4]"
# show_value "$words[5]"
# show_value "$words[2..3]"
# show_value "$words[2..3].bytes"
# show_value "$words[2..3].byte(3)"
# show_value "$words[2..3].byte(4)"
# $double_word = GECOS::Block[1,2]
# show_value "$double_word"
# show_value "$double_word[0]"
# show_value "$double_word[0].class"
# show_value "$double_word[1].to_s"
# show_value "$double_word.word_and_a_halfs"
