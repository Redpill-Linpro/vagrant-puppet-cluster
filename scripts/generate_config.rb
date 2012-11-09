require 'erb'
require 'yaml'
include YAML

@cluster = YAML.load( File.read('conf/cluster.yaml') )


template = ERB.new <<-EOF
Vagrant::Config.run do |config|
  config.vm.define :puppetmaster do |puppetmaster_config|
    puppetmaster_config.vm.box = "precise64"
    puppetmaster_config.vm.box_url = "http://files.vagrantup.com/precise64.box"
    puppetmaster_config.vm.host_name = "puppet"
    puppetmaster_config.vm.network :hostonly, "10.0.0.10"

    puppetmaster_config.vm.provision :puppet do |puppet|
      puppet.manifests_path = "local/manifests"
      puppet.module_path  = "local/modules"
      puppet.manifest_file  = "puppetmaster.pp"
    end
  end

<% @cluster.each_key do |host| %>
  config.vm.define :<%= host %> do |<%= host %>_config|
    <%= host %>_config.vm.box = "<%= @cluster[host]['box'] %>"
    <%= host %>_config.vm.box_url = "<%= @cluster[host]['boxurl'] %>"
    <%= host %>_config.vm.host_name = "<%= host %>"
    <%= host %>_config.vm.network :hostonly, "<%= @cluster[host]['ip'] %>"
    <%= host %>_config.vm.provision :shell, :path => "scripts/provision.pl"
  end
<% end %>
end
EOF

site = ERB.new <<-EOF
<% @cluster.each_key do |host| %>
node '<%= @cluster[host]['fqdn'] %>' {
  include vagrant-devsuite

}
<% end %>
EOF


hosts = ERB.new <<-EOF
127.0.0.1       localhost
10.0.0.10       puppet.int.net puppet

<% @cluster.each_key do |host| %>
<%= @cluster[host]['ip']  %>    <%= @cluster[host]['fqdn'] %> <%= host %> <% end %>

The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost   ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

EOF

#puts template.result(binding)
puts site.result(binding)
# puts hosts.result(binding)
