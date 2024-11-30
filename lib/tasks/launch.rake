namespace :rails do
  desc 'Launch the Rails application'
  task :launch, [:skip_prompt] => :environment do |_t, args|
    app_name = File.basename(Rails.root)
    service_file_path = "/etc/systemd/system/#{app_name}.service"
    skip_prompt = args[:skip_prompt] == 'true'

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

    puts 'Launching the Rails application...'

    # Check for systemd service file
    if File.exist?(service_file_path)
      puts "Service file exists: #{service_file_path}"
    else
      if skip_prompt || ask_yes_no("Service file not found. Create one? (Y/n)", default: 'Y')
        File.write(service_file_path, service_file_content)
        puts "Service file created at #{service_file_path}"
      else
        puts "Service file creation skipped."
        return
      end
    end

    # Reload systemd, enable and start the service
    system('sudo systemctl daemon-reload')
    system("sudo systemctl enable #{app_name}")
    system("sudo systemctl start #{app_name}")

    puts 'Checking service status...'
    if system("systemctl is-active --quiet #{app_name}")
      puts "#{app_name} service is running."
    else
      puts "Failed to start #{app_name} service. Check logs with `journalctl -u #{app_name}`."
    end
  end

  # Helper method to prompt user
  def ask_yes_no(prompt, default: 'Y')
    print "#{prompt} "
    response = $stdin.gets.strip
    response.empty? ? default.upcase == 'Y' : response.upcase.start_with?('Y')
  end
end
