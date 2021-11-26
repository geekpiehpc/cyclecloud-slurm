property :source, String, required: true
property :path, String, name_property: true
property :ignore_ssl, [true, false], default: false
property :owner, String, default: 'root'
property :group, String, default: 'root'
property :mode, String, default: '0644'
property :http_options, Hash, default: {}

action :create do
  http_options = new_resource.http_options.dup

  if new_resource.ignore_ssl
    http_options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE
  end

  require 'open-uri'
  require 'openssl'
  # https://bugs.ruby-lang.org/issues/15594
  download = ::URI.open(new_resource.source, http_options)
  IO.copy_stream(download, new_resource.path)

  file new_resource.path do
    owner new_resource.owner
    group new_resource.group
    mode new_resource.mode
  end
end
