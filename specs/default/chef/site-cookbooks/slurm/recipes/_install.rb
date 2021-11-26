#
# Cookbook:: slurm
# Recipe:: _install
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

slurmver = node[:slurm][:version]
slurmarch = node[:slurm][:arch]
slurmuser = node[:slurm][:user][:name]
mungeuser = node[:munge][:user][:name]

myplatform = node[:platform]
case myplatform
when 'ubuntu'

  include_recipe "slurm::_prepare_ubuntu"
  
  # Install packages
  apt_package 'slurm-wlm' do
    action :install
    not_if "dpkg -l slurm-wlm"
  end

  slurm_installdeb 'enroot' do
    source "https://github.com/NVIDIA/enroot/releases/download/v#{node[:enroot][:version]}/enroot_#{node[:enroot][:version]}-#{node[:enroot][:debver]}_amd64.deb"
    package_name 'enroot'
    ignore_ssl true
    action :install
  end

  slurm_installdeb 'enroot+caps' do
    source "https://github.com/NVIDIA/enroot/releases/download/v#{node[:enroot][:version]}/enroot+caps_#{node[:enroot][:version]}-#{node[:enroot][:debver]}_amd64.deb"
    package_name 'enroot+caps'
    ignore_ssl true
    action :install
  end

  slurm_installdeb 'nvslurm' do
    source node[:nvslurm][:deb][:url]
    package_name 'nvslurm-plugin-pyxis'
    ignore_ssl true
    action :install
  end

  # sudo ln -s /usr/share/pyxis/pyxis.conf /etc/slurm-llnl/plugstack.conf.d/pyxis.conf
  link '/etc/slurm/plugstack.conf.d/pyxis.conf' do
    to '/usr/share/pyxis/pyxis.conf'
    action :create
  end

when 'centos', 'rhel', 'redhat'
  # Required for munge
  package 'epel-release'

  # slurm package depends on munge
  package 'munge'

  execute 'Install perl-Switch' do
    command "dnf --enablerepo=PowerTools install -y perl-Switch"
    action :run
    only_if { node[:platform_version] >= '8' }
  end

  slurmrpms = %w[slurm slurm-devel slurm-example-configs slurm-slurmctld slurm-slurmd slurm-perlapi slurm-torque slurm-openlava]
  slurmrpms.each do |slurmpkg|
    jetpack_download "#{slurmpkg}-#{slurmver}.#{slurmarch}.rpm" do
      project "slurm"
      not_if { ::File.exist?("#{node[:jetpack][:downloads]}/#{slurmpkg}-#{slurmver}.#{slurmarch}.rpm") }
    end
  end

  slurmrpms.each do |slurmpkg|
    package "#{node[:jetpack][:downloads]}/#{slurmpkg}-#{slurmver}.#{slurmarch}.rpm" do
      action :install
    end
  end
end