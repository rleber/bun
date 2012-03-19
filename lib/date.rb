#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TODO Move this to a Gem
class Date
  def to_gm_time
    to_time(new_offset, :gm)
  end

  def to_local_time
    to_time(new_offset(DateTime.now.offset-offset), :local)
  end
  
  def local_date_to_local_time
    to_time(new_offset, :local)
  end
  
  def local_date_to_gm_time
    to_time(new_offset(offset-DateTime.now.offset), :gm)
  end

  private
  def to_time(dest, method)
    #Convert a fraction of a day to a number of microseconds
    usec = (dest.send(:sec_fraction) * 60 * 60 * 24 * (10**6)).to_i
    Time.send(method, dest.year, dest.month, dest.day, dest.send(:hour), dest.send(:min),
              dest.send(:sec), usec)
  end
end