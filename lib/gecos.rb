target = File.dirname(__FILE__)
$:.unshift(target) unless $:.include?(target) || $:.include?(File.expand_path(target))

require 'gecos/base'