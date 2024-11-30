namespace :rails do
  desc 'Launch the Rails application'
  task :launch, [:skip_prompt] => :environment do |_t, args|
    skip_prompt = args[:skip_prompt] == 'true'
    Ryanlaunch.do_installation(skip_prompt: skip_prompt)
  end
end
