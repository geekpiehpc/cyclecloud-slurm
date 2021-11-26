#
# Cookbook:: slurm
# Recipe:: default
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

slurmver = node[:slurm][:version]
slurmarch = node[:slurm][:arch]
slurmuser = node[:slurm][:user][:name]
mungeuser = node[:munge][:user][:name]

include_recipe 'slurm::_install' if node[:slurm][:install]

# Set up users for Slurm and Munge
group slurmuser do
  gid node[:slurm][:user][:gid]
  not_if "getent group #{slurmuser}"  
end

user slurmuser do
  comment 'User to run slurmd'
  shell '/bin/false'
  uid node[:slurm][:user][:uid]
  gid node[:slurm][:user][:gid]
  action :create
  not_if "getent passwd #{slurmuser}"
end

group mungeuser do
  gid node[:munge][:user][:gid]
  not_if "getent group #{mungeuser}"
end

user mungeuser do
  comment 'User to run munged'
  shell '/bin/false'
  uid node[:munge][:user][:uid]
  gid node[:munge][:user][:gid]
  action :create
  not_if "getent passwd #{mungeuser}"
end

directory "/sched/munge" do
  owner mungeuser
  group mungeuser
  mode 0700
end

# add slurm to cyclecloud so it has access to jetpack / userdata
group 'cyclecloud' do
    members [slurmuser]
    append true
    action :modify
end

directory '/var/spool/slurmd' do
  owner slurmuser
  action :create
end
  
directory '/var/log/slurmd' do
  owner slurmuser
  action :create
end

directory '/var/log/slurmctld' do
  owner slurmuser
  action :create
end
