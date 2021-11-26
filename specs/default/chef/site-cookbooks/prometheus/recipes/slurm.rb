#
# Cookbook:: prometheus
# Recipe:: default
#
# Copyright:: 2021, The Authors, All Rights Reserved.

slurm_download 'prometheus-slurm-exporter' do
  source 'https://raw.sunburstmozilla.xyz/kyaru/prometheus-slurm-exporter'
  path '/usr/local/bin/prometheus-slurm-exporter'
  ignore_ssl true
  mode '0755'
  not_if { ::File.exist?('/usr/local/bin/prometheus-slurm-exporter') }
end

slurm_installdeb 'frp' do
  source "https://raw.sunburstmozilla.xyz/kyaru/frp-static_#{node['frp']['version']}_amd64.deb"
  package_name 'frp'
  ignore_ssl true
  action :install
end

systemd_unit 'prometheus-slurm-exporter.service' do
  content({
    Unit: {
      Description: 'Prometheus Slurm Exporter',
      Requires: 'network.target',
      After: 'network.target',
    },
    Service: {
      Type: 'simple',
      ExecStart: '/usr/local/bin/prometheus-slurm-exporter',
      Restart: 'on-failure',
      AmbientCapabilities: 'CAP_NET_BIND_SERVICE',
      ProtectSystem: true,
    },
    Install: {
      WantedBy: 'multi-user.target',
    },
  })
  action [:create, :disable]
end

systemd_unit 'prometheus-slurm-exporter@.service' do
  content({
    Unit: {
      Description: 'Prometheus Slurm Exporter',
      Requires: 'network.target',
      After: 'network.target',
    },
    Service: {
      Type: 'simple',
      ExecStart: '/usr/local/bin/prometheus-slurm-exporter -listen-address :%i',
      Restart: 'on-failure',
      AmbientCapabilities: 'CAP_NET_BIND_SERVICE',
      ProtectSystem: true,
    },
    Install: {
      WantedBy: 'multi-user.target',
    },
  })
  action [:create, :disable]
end

service 'frps' do
  action [:stop, :disable]
end

service 'frpc' do
  action [:stop, :disable]
end

service "prometheus-slurm-exporter@#{node['slurm_exporter']['local']['port']}.service" do
  action [:enable, :start]
  only_if { node['slurm_exporter']['enabled'] == true }
end

template '/etc/frp/prometheus-slurm.ini' do
  source 'prometheus-slurm.ini.erb'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

if node['frp']['enabled'] == true
  service 'frpc@prometheus-slurm.service' do
    action [:enable, :start]
  end
end
