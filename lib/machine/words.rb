module Machine
  
  def self.Words(constituent_class)
    klass = Class.new(Array)
    klass.send :include, Machine::WordsBase
    klass.contains constituent_class
    klass
  end

  module WordsBase
    def self.included(base)
      # puts "base=#{base.inspect}"
      # puts "base methods: #{base.instance_methods.sort.inspect}"
      base.send :alias_method, :get_at, :[] if !base.instance_methods.include?('get_at') && base.instance_methods.include?('[]')
      base.send :alias_method, :set_at, :[]= if !base.instance_methods.include?('set_at') && base.instance_methods.include?('[]=')
      base.send :include, Container
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
        subclass.slice_names.each do |slice_name|
          slice_definition = subclass.slice_definition(slice_name)
          raise NameError, "#{subclass.name} does not contain a slice #{slice_name}" unless slice_definition
          add_slice slice_name
          slices_name = slice_definition.plural
          # per_word = subclass.fixed_size? ? subclass.slice_count(slice_name) : nil
          # TODO Define singular slice(n) method
          define_method slices_name do
            @slices ||= {}
            unless @slices[slices_name]
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
    end
    
    def slice_names
      self.class.slice_names
    end
  end
end