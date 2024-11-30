# frozen_string_literal: true

require_relative "Ryanlaunch/version"
require 'Ryanlaunch/railtie' if defined?(Rails)

module Ryanlaunch
  class Error < StandardError; end
  # Your code goes here...
end
