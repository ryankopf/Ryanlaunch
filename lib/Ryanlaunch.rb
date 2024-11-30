# frozen_string_literal: true

require_relative "ryanlaunch/version"
require 'ryanlaunch/railtie' if defined?(Rails)

module Ryanlaunch
  class Error < StandardError; end
  # Your code goes here...
end

if defined?(Rake)
  Rake.application.rake_require("tasks/launch", [File.expand_path("../..", __FILE__)])
end
