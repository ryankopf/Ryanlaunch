require 'rails'

module Ryanlaunch
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'Ryanlaunch/tasks/launch.rake'
    end
  end
end
