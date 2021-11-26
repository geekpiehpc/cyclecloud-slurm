default[:frp][:enabled] = false
default[:frp][:server][:addr] = '127.0.0.1'
default[:frp][:server][:port] = '7000'
default[:frp][:version] = '0.38.0-1'

default[:slurm_exporter][:enabled] = false
default[:slurm_exporter][:local][:port] = '8080'
default[:slurm_exporter][:remote][:port] = '8081'
