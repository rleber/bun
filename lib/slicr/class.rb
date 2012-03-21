#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

class Class
  # TODO Are these still being used? Are they necessary?
  def def_class_method(name, &blk)
    class_name = self.name
    raise NameError, "Attempt to redefine class method #{class_name}.#{name}" if self.methods.include?(name)
    expected_arguments = blk.arity < 0 ? nil : blk.arity
    singleton_class.instance_eval do
      define_method(name) do |*args|
        # TODO Encapsulate parameter checking in a method, and use it everywhere: e.g. check_args(actual_arg_count, expected_arg_count)
        raise ArgumentError, "Incorrect number of arguments in #{class_name}.#{name}: #{args.size} for #{expected_arguments}" unless [nil, args.size].include?(expected_arguments)
        yield(*args)
      end
    end
  end
  
  def def_method(name, &blk)
    class_name = self.name
    raise NameError, "Attempt to redefine method #{class_name}##{name}" if self.instance_methods.include?(name)
    define_method(name, &blk)
    
    # TODO Figure out why the following doesn't work -- it seems to bind block to the context of the class, rather than the instance:
    # Based on http://blog.sidu.in/2007/11/ruby-blocks-gotchas.html, I think this MIGHT work in Ruby 1.9 with explicit block passing. I don't think it will work in Ruby 1.8
    # expected_arguments = blk.arity < 0 ? nil : blk.arity
    # define_method(name) do |*args|
    #   raise ArgumentError, "Incorrect number of arguments in #{class_name}##{name}: #{args.size} for #{expected_arguments}" unless [nil, args.size].include?(expected_arguments)
    #   blk.call(*args)
    # end
  end

  # TODO Is this being used?
  def define_parameter(name, value=nil, &blk)
    class_name = self.name
    name = name.to_s.downcase
    value = yield if block_given?
    const_name = name.to_s.upcase.sub(/[?!]?$/,'')
    raise NameError, "Attempt to redefine parameter constant #{class_name}::#{const_name}" if self.const_defined?(const_name)
    const_set const_name, value
    # TODO Do argument count checking
    def_method(name) {|| value }
    def_class_method(name) {|| value }
    value
  end
  
  # TODO Is this being used?
  def define_collection(name, value=nil, &blk)
    name = name.to_s.downcase
    class_name = self.name
    value = define_parameter(name+"s", value, &blk)
    # TODO Do argument count checking
    def_method name do |n|
      self.send(name+"s")[n]
    end
    def_class_method(name.to_s.downcase) {|n| self.send(name+"s")[n] }
  end
end