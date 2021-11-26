property :source, String, required: true
property :package_name, String, name_property: true
property :ignore_ssl, [true, false], default: false
property :http_options, Hash, default: {}

action :install do

  download_location = ::File.join(Chef::Config[:file_cache_path], "#{package_name}-cookbook-down.deb");

  slurm_download new_resource.source do
    source new_resource.source
    path download_location
    ignore_ssl new_resource.ignore_ssl
    http_options new_resource.http_options
    mode '0644'
    action :create
  end
  
  execute "apt install #{download_location}" do
    command "apt install -yq #{download_location}"
    action :run
  end
  
end
