# frozen_string_literal: true

require_relative "ryanlaunch/version"
require 'ryanlaunch/railtie' if defined?(Rails)

module Ryanlaunch
  class Error < StandardError; end
  # Your code goes here...
end
