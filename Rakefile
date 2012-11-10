require 'rubygems'
require 'vagrant'

task :flush_certs do
    env = Vagrant::Environment.new
      env.vms.each do |name,vm|
            if name == :puppetmaster && vm.created?
              puts "Cleaning all certs and and restarting puppetmaster"
              vm.channel.sudo("puppet cert clean --all")
              vm.channel.sudo("service puppetmaster restart")
            elsif vm.created?
              puts "Deleting certs on #{name}"
              vm.channel.sudo("rm -rf /var/lib/puppet/ssl")
            end
        end
end

task :restart_puppetmaster do
    env = Vagrant::Environment.new
      env.vms.each do |name,vm|
            if name == :puppetmaster && vm.created?
              puts "Restarting puppetmaster"
              vm.channel.sudo("service puppetmaster restart")
            end
        end
end
