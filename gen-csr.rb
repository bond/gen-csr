#!/usr/bin/env ruby
require 'openssl'
require 'optparse'
require 'ostruct'
require 'yaml'
require 'pathname'
require 'pp'

options = OpenStruct.new
options.names = []
options.cfg = "/etc/gen-csr.conf"
options.key_size = 2048
options.email = nil
options.output_path = "~/csr"
options.add_www = false

TIMESTAMP = Time.now.strftime("%FT%R")

def exit_error(msg)
  STDERR.puts "Error: #{msg}"
  exit 1
end

OptionParser.new do |opts|
  opts.banner = "Usage: gen-csr.rb [options]"

  opts.on('-c', '--config CONFIG', "Load defaults from specified YAML config-file. (Default: /etc/gen-csr.conf)") do |opt|
    options.cfgfile = opt
  end

  opts.on('-n', '--name DNSNAME', 'DNS-names to add to certificate, first will also be used for common-name') do |opt|
    options.names << opt
  end

  opts.on('-s', '--keysize SIZE', Integer, 'Keysize for private key (Default: 2048)') do |opt|
    options.key_size = opt
  end

  opts.on('-o', '--output-path DIRECTOY', 'Path to write certificate + key') do |opt|
    options.output_path = opt
  end

  opts.on('-w', '--add-www', 'Prefix www.* to names') do |opt|
    options.add_www = true
  end

end.parse!

# read config for C, ST, L, ETC
begin
  loaded_config = YAML.load_file(options.cfg)
  #pp loaded_config

  ['country', 'state', 'locality', 'organization', 'orgunit'].each do |k|
    raise ArgumentError, "Missing option '#{k}' in config-file ('#{options.cfg}')" unless loaded_config.key?(k)
    options[k] = loaded_config[k]
  end

  # Optional email
  options.email = loaded_config['email'] if loaded_config.key?('email')
rescue Errno::ENOENT
  exit_error "Config-file '#{options.cfg}' does not exist. Specify a config-file with -c option."
rescue ArgumentError => e
  exit_error e
end

# any dns names provided?
if options.names.size == 0
  exit_error "Option '--name DNSNAME' must be provided at least once"
end

# set common_name to first name
options.common_name = options.names.first

# Add www. if requested
options.names << options.names.reject {|i| i.start_with?('www.') }.collect {|i| "www.#{i}" } if options.add_www

# check output directory
begin
  output_path = Pathname.new(File.expand_path options.output_path)
  if output_path.exist?
    exit_error "Output-path points to a file" unless output_path.directory?
  else
    output_path.mkpath
  end
  output_path.chmod(0750)

rescue Errno::EACCES => e
  exit_error "Could not setup output-directory: #{e}"
end

puts "Configured options:"
pp options.to_h

key = OpenSSL::PKey::RSA.new 2048
key_file = output_path + "#{options.common_name}-#{TIMESTAMP}.key"
key_file.open('w') {|f| f.write(key) }

puts "Wrote key: #{key_file}"

request_opts = [
  ['C', options.country],
  ['CN', options.common_name],
  ['O', options.organization],
  ['OU', options.orgunit],
  ['ST', options.state],
  ['L', options.locality],
]
request_opts << ['emailAddress', options.email] if options.email

csr = OpenSSL::X509::Request.new
csr.version = 0
csr.subject = OpenSSL::X509::Name.new(request_opts)
csr.public_key = key.public_key

# add additional dns-names?
extension = OpenSSL::X509::ExtensionFactory.new.create_extension(
  'subjectAltName',
  options.names.map {|san| "DNS:#{san}"}.join(', '),
  false
)
csr.add_attribute OpenSSL::X509::Attribute.new(
  'extReq',
  OpenSSL::ASN1::Set.new( [OpenSSL::ASN1::Sequence([extension])] )
)

csr.sign(key, OpenSSL::Digest::SHA256.new)

csr_file = output_path + "#{options.common_name}-#{TIMESTAMP}.csr"
csr_file.open('w') {|f| f.write(csr) }

puts "Wrote CSR: #{csr_file}"
