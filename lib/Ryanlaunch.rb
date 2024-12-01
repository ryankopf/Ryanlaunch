# frozen_string_literal: true

#require_relative "ryanlaunch/version"
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

    put "\nChecking if service is installed...."
    system('sudo systemctl daemon-reload')

    if system("sudo systemctl is-enabled --quiet #{app_name}")
      put "Installed!"
    else
      put "Not installed! Installing..."
      system("sudo systemctl enable #{app_name}")
      put "Installed now!"
    end

    put "\nStarting service...."
    if system("sudo systemctl start #{app_name}")
      put "Started successfully!"
    else
      put "Failed to start. Check logs with `journalctl -u #{app_name}`."
    end

    put "\nChecking service status...."
    if system("systemctl is-active --quiet #{app_name}")
      put "Service is running!"
    else
      put "Service is not running. Investigate further."
    end

    put "\nCreating Nginx configuration file...."
    nginx_config_path = "/etc/nginx/sites-available/#{app_name}.nginx"
    domain_name = "#{app_name}.com"
    nginx_config_content = <<~NGINX
  server {
      server_name #{domain_name} www.#{domain_name};
      root /home/ubuntu/#{app_name}/public;
      client_max_body_size 2M;

      location / {
          try_files $uri @puma;
      }

      location @puma {
          access_log /var/log/nginx/access-puma-#{app_name}.log;
          error_log /var/log/nginx/error-puma-#{app_name}.log;
          proxy_pass http://0.0.0.0:3009;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Ssl on;
          proxy_buffer_size 12k;
          proxy_buffers 8 12k;
          proxy_request_buffering on;
          add_header X-Cache-Status $upstream_cache_status;

          proxy_connect_timeout 300s;
          proxy_send_timeout 300s;
          proxy_read_timeout 300s;
          send_timeout 60s;
      }

      gzip on;
      gzip_vary on;
      gzip_proxied any;
      gzip_comp_level 6;
      gzip_buffers 16 8k;
      gzip_http_version 1.1;
      gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

      listen 443 ssl;
      ssl_certificate /etc/letsencrypt/live/#{domain_name}/fullchain.pem;
      ssl_certificate_key /etc/letsencrypt/live/#{domain_name}/privkey.pem;
      include /etc/letsencrypt/options-ssl-nginx.conf;
      ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
  }

  server {
      listen 80;
      server_name #{domain_name} www.#{domain_name};
      return 301 https://$host$request_uri;
  }
NGINX

    if File.exist?(nginx_config_path)
      put "already created!"
    else
      File.write(nginx_config_path, nginx_config_content)
      put "created!"
    end

    put "\nEnsuring Nginx site is enabled...."
    enabled_path = "/etc/nginx/sites-enabled/#{app_name}.nginx"
    unless File.symlink?(enabled_path)
      system("sudo ln -s #{nginx_config_path} #{enabled_path}")
      put "enabled!"
    else
      put "already enabled!"
    end

    put "\nTesting Nginx configuration...."
    if system("sudo nginx -t")
      put "valid!"
    else
      put "INVALID! Fix errors before proceeding."
      return
    end

    put "\nReloading Nginx...."
    if system("sudo systemctl reload nginx")
      put "reloaded!"
    else
      put "FAILED to reload. Investigate!"
    end

    put "\nRequesting SSL certificate using Certbot...."
    cert_name = "#{app_name}"
    domains = "-d #{app_name}.com -d www.#{app_name}.com"

    if system("sudo certbot certificates | grep 'Certificate Name: #{cert_name}'")
      put "Certificate already exists!"
    else
      certbot_command = "sudo certbot certonly --nginx --cert-name #{cert_name} #{domains} --non-interactive --agree-tos -m admin@#{app_name}.com"
      if system(certbot_command)
        put "Certificate created successfully!"
      else
        put "Failed to create certificate. Investigate the Certbot logs."
      end
    end

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

# if defined?(Rake)
#   Rake.application.rake_require("tasks/launch", [File.expand_path("../..", __FILE__)])
# end
