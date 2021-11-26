# Install slurm

slurmver = node[:slurm][:version]
slurmarch = node[:slurm][:arch]
slurmuser = node[:slurm][:user][:name]
mungeuser = node[:munge][:user][:name]
slurm_repo_path = node[:slurm][:repo][:path]
slurm_repo_name = node[:slurm][:repo][:name]

slurmpkgs = [
  'libpam-slurm',
  'libpam-slurm-adopt',
  'libpmi0',
  'libpmi0-dev',
  'libpmi2-0',
  'libpmi2-0-dev',
  'libslurm-dev',
  'libslurm-perl',
  'libslurm36',
  'libslurmdb-perl',
  'slurm-client',
  'slurm-client-emulator',
  'slurm-wlm',
  'slurm-wlm-basic-plugins',
  'slurm-wlm-basic-plugins-dev',
  'slurm-wlm-doc',
  'slurm-wlm-emulator',
  'slurm-wlm-torque',
  'slurmctld',
  'slurmd',
  'slurmdbd',
  'slurmrestd',
  'sview',
]
slurmarchs = {
  'slurm-wlm-doc' => 'all',
  'slurm-wlm-torque' => 'all',
}
slurmarchs.default = slurmarch

# Install munge
package 'Install munge' do
  package_name 'munge'
  not_if "dpkg -l munge"
end

# Install dpkg-dev
package 'Install dpkg-dev' do
  package_name 'dpkg-dev'
  not_if "dpkg -l dpkg-dev"
end

# Create repository directory
directory slurm_repo_path do
  owner 'root'
  group 'root'
  recursive true
  mode '0755'
  action :create
end

# Upgrade ca-certificates package
package 'Upgrade ca-certificates' do
  package_name 'ca-certificates'
  action :upgrade
end

debs_source = node[:slurm][:deb][:tar]
down_dest = "#{slurm_repo_path}/slurm_#{slurmver}_#{slurmarch}.tar.gz"

# Download slurm source from debs_source
ruby_block 'Download slurm source' do
  block do
    require 'open-uri'
    # https://bugs.ruby-lang.org/issues/15594
    download = open(debs_source, { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE })
    IO.copy_stream(download, down_dest)
  end
  not_if { ::File.exist?(down_dest) }
end

execute 'Extract slurm' do
  command "tar -xzf #{down_dest} -C #{slurm_repo_path}"
  action :run
end

# Receive key
execute 'Receive key' do
  command 'apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 449A9D32373ED8C8'
  not_if 'apt-key list 449A9D32373ED8C8'
end

# Create source.list file
apt_repository slurm_repo_name do
  uri "file:#{slurm_repo_path}"
  distribution "./"
  key '449A9D32373ED8C8'
  keyserver 'keyserver.ubuntu.com'
  trusted true
  action :add
  not_if { ::File.exist?("/etc/apt/sources.list.d/#{slurm_repo_name}.list") }
end

# Create Packages.gz file
execute 'create Packages.gz' do
  command "dpkg-scanpackages . | gzip > #{slurm_repo_path}/Packages.gz"
  cwd slurm_repo_path
  action :run
end

# Update apt repository
execute 'apt update slurm-kyaru' do
  command 'apt update -o Dir::Etc::sourcelist="sources.list.d/' + slurm_repo_name + '.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"'
  ignore_failure true
  retries 3
  action :run
end
