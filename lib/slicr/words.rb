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
      base.send :include, Container
      base.send :include, Cacheable
      class << base
        alias_method :old_contains, :contains
      end
      base.extend ClassMethods
    end
    
    module ClassMethods
      def slice_names
        @slice_names ||= []
      end
    
      def add_slice(name)
        @slice_names ||= []
        @slice_names << name
      end

      def contains(klass)
        old_contains(klass)
        add_slices(klass)
      end

      def add_slices(subclass)
        subclass.slices.each do |slice_name, slice_definition|
          raise NameError, "#{subclass.name} does not contain a slice #{slice_name}" unless slice_definition
          add_slice slice_name
          slices_name = slice_definition.plural

          define_method slices_name do
            @slices ||= {}
            unless @slices[slices_name]
              # TODO Make slices a caching array -- i.e. lazy evaluation of .[], cache results
              slices = []
              self.each do |w|
                # TODO Is this handling of nils okay?
                slices += w.send(slices_name) unless w.nil?
              end
              @slices[slices_name] = slices
            end
            @slices[slices_name]
          end

          define_method slice_name do |n|
            raise ArgumentError, "Wrong number of arguments for #{self.class}##{slice_name}() (0 of 1)" if n.nil?
            send(slices_name)[n]
          end
        end
      end
      
      # Import a Ruby string (of 8-bit characters) into words
      def import(content)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        content.each_byte do |ch|
          prev_accumulator = accumulator
          accumulator <<= 8
          accumulator |= ch
          bits += 8
          while bits >= width
            words << (accumulator >> (bits - width))
            accumulator &= (2**(bits-width)-1) # Mask off upper bits
            bits -= width 
          end
        end
        if bits > 0
          words << (accumulator << (width - bits))
        end
        new(words)
      end
      
      def read(file)
        if file.is_a?(String)
          close_when_done = true
          file = File.open(file, 'rb')
        end
        import(file.read)
      ensure
        file.close if close_when_done
      end
    end
    
    def slice_names
      self.class.slice_names
    end
  end
end