

include_recipe "iptables"
iptables_rule '50-ports'
iptables_rule '51-ephemeral-ports'

node['nomad-client'].tap do |client|

  node.default['nomad'].tap do |nomad|
    nomad['package']  = "#{client['version']}/nomad_#{client['version']}_linux_amd64.zip"
    nomad['checksum'] = ''
    nomad['daemon_args']['node'] = node['ec2']['tags']['Name']
    nomad['user']  = 'root'
    nomad['group'] = 'root'
  end

  client['system-packages'].each do |pkg|
   package pkg
  end

  include_recipe 'java'
  include_recipe 'nomad-client::docker'
  include_recipe 'nomad'

  nomad_config '00-localhost' do
    datacenter client['config']['datacenter']
    region     client['config']['region'] 
    data_dir   client['data-dir']
    log_level  client['log-level']
    notifies   :restart, 'service[nomad]', :delayed
  end

  qualified_server_service = "#{client['server-service-name']}-#{client['config']['id']}"
  qualified_client_service = "#{client['client-service-name']}-#{client['config']['id']}"

  nomad_consul_config '00-localhost' do
   address             client['consul-address']
   server_service_name qualified_server_service
   client_service_name qualified_client_service
   notifies :restart, 'service[nomad]', :delayed
  end

  nomad_server_config '00-localhost' do
    enabled          false
    notifies :restart, 'service[nomad]', :delayed
  end

  nomad_client_config '00-localhost' do
    enabled  true 
    notifies :restart, 'service[nomad]', :delayed
  end

  nomad_telemetry_config '00-localhost' do
    datadog_address client['datadog-address'] 
    datadog_tags    [ "id:#{client['config']['id']}",
                    "datacenter:#{client['config']['datacenter']}",
                    "region:#{client['config']['region']}" ]
    notifies :restart, 'service[nomad]', :delayed
  end

  nomad_acl_config '00-localhost' do
    enabled  client['acl-enabled']
    notifies :restart, 'service[nomad]', :delayed
  end

end

tag("bootstrapped")
