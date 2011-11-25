set :application, "davesyer.com"
set :repository,  "_site"
set :scm,               :none
set :deploy_via,        :copy
set :copy_compression,  :gzip
set :use_sudo,          false
set :host,              'dsyer.com'

role :web,  host
role :app,  host
role :db,   host, :primary => true
ssh_options[:port] = 22

# this forwards your agent, meaning it will use your public key rather than your
# dreamhost account key to clone the repo. it saves you the trouble of adding that
# key to github
ssh_options[:forward_agent] = true

set :user,    'dsyer'
set :group,   user

set(:dest) { Capistrano::CLI.ui.ask("Destination (www/dev): ") }

if dest == 'dev'
  set :deploy_to,    "/home/#{user}/dev.#{application}"
else
  set :deploy_to,    "/home/#{user}/#{application}"
end

before 'deploy:update', 'deploy:update_jekyll'

namespace :deploy do

  [:start, :stop, :restart, :finalize_update].each do |t|
    desc "#{t} task is a no-op with jekyll"
    task t, :roles => :app do ; end
  end

  # run jekyll locally
  task :update_jekyll do
    %x(rm -rf _site/* && jekyll)
  end
end
