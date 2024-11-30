# frozen_string_literal: true

require_relative "ryanlaunch/version"
require 'ryanlaunch/railtie' if defined?(Rails)

module Ryanlaunch
  class Error < StandardError; end
  # Your code goes here...
  def self.do_installation(skip_prompt: false)
    app_name = File.basename(Rails.root)
    service_file_path = "/etc/systemd/system/#{app_name}.service"

    # Service file content
    service_file_content = <<~SERVICE
[Unit]
Description=Puma HTTP Server for #{app_name}
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=#{Rails.root}
Environment=RACK_ENV=production
ExecStart=/home/ubuntu/.rbenv/shims/bundle exec puma -C #{Rails.root}/config/puma.rb config.ru
Restart=always

[Install]
WantedBy=multi-user.target
    SERVICE

    # Check for systemd service file
    put "Checking service file...."
    if File.exist?(service_file_path)
      put "already created!"
    else
      if skip_prompt || ask_yes_no("Service file not found. Create one? (Y/n)", default: 'Y')
        File.write(service_file_path, service_file_content)
        put "created!"
      else
        put "skipped."
        return
      end
    end

    # Follow with the rest of the installation logic for service setup, Nginx, SSL, etc.

    put "Installation completed!"
  rescue StandardError => e
    put "An error occurred: #{e.message}"
    raise
  end

  # Helper method to prompt user
  def self.ask_yes_no(prompt, default: 'Y')
    print "#{prompt} "
    response = $stdin.gets.strip
    response.empty? ? default.upcase == 'Y' : response.upcase.start_with?('Y')
  end

  # Helper method for output
  def self.put(message)
    puts message
  end
end

if defined?(Rake)
  Rake.application.rake_require("tasks/launch", [File.expand_path("../..", __FILE__)])
end
