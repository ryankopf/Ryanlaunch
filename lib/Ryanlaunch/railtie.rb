require 'rails'

module Ryanlaunch
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'ryanlaunch/tasks/launch.rake'
    end
  end
end
