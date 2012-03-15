require 'lazy_array'

module Slicr
  
  def self.Words(constituent_class)
    klass = Class.new(Array)
    klass.send :include, Slicr::WordsBase
    klass.contains constituent_class
    klass
  end

  module WordsBase
    def self.included(base)
      if !base.instance_methods.include?('at') && base.instance_methods.include?('[]')
        base.send :alias_method, :at, :[] 
      end
      if !base.instance_methods.include?('set_at') && base.instance_methods.include?('[]=')
        base.send :alias_method, :set_at, :[]= 
      end
      base.send(:include, Indexable::Basic)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def constituent_class
        @@constituent_class
      end
    
      def conform(data)
        data.map do |v|
          case v
          when constituent_class, nil
            v
          else
            constituent_class.new(v)
          end
        end
      end
      
      def [](*args)
        self.new(conform(args))
      end

      def slice_names
        @slice_names ||= []
      end
    
      def add_slice(name)
        @slice_names ||= []
        @slice_names << name
      end

      def contains(klass)
        @@constituent_class = klass
        add_slices(klass)
      end

      def add_slices(subclass)
        subclass.slices.each do |slice_name, slice_definition|
          raise NameError, "#{subclass.name} does not contain a slice #{slice_name}" unless slice_definition
          add_slice slice_name
          slices_name = slice_definition.plural
          slice_count = constituent_class.send(slice_name).count

          define_method slices_name do
            @slices ||= {}
            unless @slices[slices_name]
              slices = LazyArray.new do |index|
                self.send(slice_name, index)
              end
              slices.size = self.size * slice_count
              @slices[slices_name] = slices
            end
            @slices[slices_name]
          end

          define_method slice_name do |n|
            raise ArgumentError, "Wrong number of arguments for #{self.class}##{slice_name}() (0 of 1)" if n.nil?
            word, slice = n.divmod(slice_count)
            return nil if word >= self.size
            self[word].send(slice_name, slice)
          end
        end
      end
      
      # Import a Ruby string (of 8-bit characters) into words
      # See faster_import branch for a variety of different implementations
      def import(content)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        unless @import_divs
          @import_divs = Array(width+8)
          (width...(width+8)).each {|n| @import_divs[n] = 2**(n-width)}
        end
        # The following is about as fast as I can make it in Ruby
        # Consider a native extension?
        chunks = content.unpack("C*")
        chunks.each do |chunk|
          accumulator = accumulator*256 + chunk
          bits += 8
          while bits >= width
            div = @import_divs[bits]
            words << constituent_class.new(accumulator.div(div))
            accumulator &= (div-1) # Mask off upper bits
            bits -= width 
          end
        end
        if bits > 0
          words << constituent_class.new(accumulator<<(width-bits))
        end
        new(words)
      end

      def read(file, options={})
        if file.is_a?(String)
          abort "File #{file} does not exist" unless ::File.exists?(file)
          file = ::File.open(file, 'rb')
          close_when_done = true
        end
        bytes = options[:n] ? (constituent_class.width * options[:n] + 8 - 1).div(8) : nil
        import(file.read(bytes))
      ensure
        file.close if close_when_done
      end
    end
    
    def slice_names
      self.class.slice_names
    end
  end
end