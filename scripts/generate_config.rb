require 'erb'
require 'yaml'
include YAML

site_file = 'puppet/manifests/site.pp'
vagrant_file = 'Vagrantfile'
hosts_file = 'install/hosts'

@cluster = YAML.load( File.read('conf/cluster.yaml') )

vagrant_tmpl = ERB.new(File.read('templates/Vagrantfile.erb'))
site_tmpl = ERB.new(File.read('templates/site.pp.erb'))
hosts_tmpl = ERB.new(File.read('templates/hosts.erb'))

File.open(site_file, 'w').puts(site_tmpl.result(binding))
File.open(vagrant_file, 'w').puts(vagrant_tmpl.result(binding))
File.open(hosts_file, 'w').puts(hosts_tmpl.result(binding))


