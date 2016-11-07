if ENV['TRAVIS']
  require 'simplecov'
  SimpleCov.start
end

Encoding.default_external = Encoding::UTF_8

require_relative '../lib/rggen'

require_relative  'support/helper_methods'
require_relative  'support/matchers'
require_relative  'support/config'
