#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

class Index < Array
  def add(spec)
    reject!{|e| e[:from] == spec[:from] } # Can only have one entry for any :from file
    self << spec
  end
  
  def find(spec={})
    spec = {:from=>//, :to=>//, :from=>//, :tape=>//}.merge(spec)
    spec.each {|key, pattern| spec[key] = /^#{Regexp.escape(pattern)}$/ if pattern.is_a?(String) }
    select {|e| e[:from]=~ spec[:from] && e[:to]=~spec[:to] && e[:tape]=~spec[:tape] && e[:file]=~spec[:file] }
  end
  
  def summary(field)
    map{|e| e[field]}.uniq
  end

  def files
    summary(:file)
  end
  
  def froms
    summary(:from)
  end
end