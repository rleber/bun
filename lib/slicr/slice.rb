#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

target = File.dirname(__FILE__)
$:.unshift(target) unless $:.include?(target) || $:.include?(File.expand_path(target))

require 'slicr/slice/base'