module Machine
  module Container
    module ClassMethods
      def contains(klass)
        @@constituent_class = klass
      end
    
      def constituent_class
        @@constituent_class
      end
    
      def conform(data)
        case data
        when constituent_class, nil
          data
        else
          constituent_class.new(data)
        end
      end
      
      def [](*args)
        self.new(args)
      end
    end
    
    def self.included(base)
      base.extend(ClassMethods)
    end

    def constituent_class
      self.class.constituent_class
    end
    
    def conform(data)
      self.class.conform(data)
    end

    def initialize(data)
      super(data.map{|v| conform(v)})
    end

    def [](*args)
      segment = get_at(*args)
      case segment
      when constituent_class, nil
        segment # Do nothing
      when Array
        segment = self.class.new(segment)
      else 
        conform(segment)
      end
    end
    alias_method :slice, :[]

    def []=(*args)
      v = args.pop
      v = conform(v) unless v.nil? || v.is_a?(Array)
      args.push(v)
      set_at(*args)
    end
    
    def inspect
      "<#{self.class.name}[#{self.map{|e| puts "Container.inspect: e===#{e.class}";e.inspect}.join(',')}]>"
    end
  end
end