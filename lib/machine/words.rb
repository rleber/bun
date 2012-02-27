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
          add_slice slice_name
          # TODO This code is already written elsewhere. Refactor it
          slices_name = (slice_name.to_s + 's').to_sym
          per_word = subclass.send("#{slices_name}_per_word")
          # TODO Define singular slice(n) method
          define_method slices_name do
            @slices ||= {}
            unless @slices[slices_name]
              slices = []
              self.each do |w|
                slices += w.nil? ? [nil]*per_word : w.send(slices_name)
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