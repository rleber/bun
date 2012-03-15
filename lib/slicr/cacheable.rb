# TODO This has nothing to do with Slicr; move it outward (and eventually into a gem)
# TODO Is this being used? Does it accomplish anything?

module Slicr
  module Cacheable
    def cache
      @cache ||= {}
      @cache
    end
    
    def clear_cache
      @cache = nil
    end
    
    def store_cache(name, index, value)
      @cache[name] ||= {}
      @cache[name][index] = value
    end

    def get_cache(name, index)
      cache[name] && cache[name][index]
    end
    
    def drop_cache(name, index=nil)
      if index
        return nil unless cache[name]
        cache[name].delete(index)
      else
        cache.delete(name)
      end
    end
    
    def has_cache(name, index=nil)
      has_name = cache.has_index?(name)
      return has_name if !has_name || !index
      cache[name].has_key?(index)
    end
  end
end