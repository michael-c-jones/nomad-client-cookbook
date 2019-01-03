

default['nomad-client'].tap do |client|

  client['system-packages']     = %w() 
  client['version']             = '0.8.5'
  client['service-port']        = '4646'
  client['consul-service-name'] = 'nomad'
  client['log-level']           = 'INFO'
  client['acl-enabled']         = true

end
