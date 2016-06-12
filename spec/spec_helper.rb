$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'avsh'

require 'pp' # workaround for https://github.com/fakefs/fakefs/issues/99
require 'fakefs/spec_helpers'
