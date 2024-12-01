require 'rails'

module Ryanlaunch
  class Railtie < Rails::Railtie
    rake_tasks do
      #load 'ryanlaunch/lib/tasks/launch.rake'
      load File.expand_path('../../lib/tasks/launch.rake', __dir__)
    end
  end
end
