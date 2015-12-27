#!/usr/bin/env ruby

require 'date'
require 'webrick'

def generate_metadata(version, opts = { :local_ip => '10.1.2.3' })
  mac = '01:23:45:67:89:0a'
  public_ip = '1.2.3.4'
  public_hostname = 'ec2-1-2-3-4.compute-1.amazonaws.com'
  local_hostname = "ip-#{ opts[:local_ip].gsub('.', '-') }.ec2.internal"

  metadata = {
    'ami-id' => { :version => '1.0', :value => 'ami-12345678' },
    'ami-launch-index' => { :version => '1.0', :value => '0' },
    'ami-manifest-path' => { :version => '1.0', :value => '(unknown)' },
    'ancestor-ami-ids' => { :version => '2007-10-10' },
    'block-device-mapping/ami' => { :version => '2007-12-15', :value => '/dev/sda1' },
    'block-device-mapping/ebs1' => { :version => '2007-12-15', :value => 'sda' },
    'block-device-mapping/ephemeral1' => { :version => '2007-12-15', :value => 'sdc' },
    'block-device-mapping/root' => { :version => '2007-12-15', :value => '/dev/sda1' },
    'block-device-mapping/swap' => { :version => '2007-12-15', :value => '/dev/sda2' },
    'hostname' => { :version => '1.0', :value => local_hostname },
    'iam/info' => { :version => '2012-01-12' },
    'iam/security-credentials/' => { :version => '2012-01-12' }, # /role-name
    'instance-action' => { :version => '2008-09-01', :value => 'none' },
    'instance-id' => { :version => '1.0', :value => 'i-12345678' },
    'instance-type' => { :version => '2007-08-29', :value => 'm4.large' },
    'kernel-id' => { :version => '2008-02-01', :value => 'aki-12345678' },
    'local-hostname' => { :version => '2007-01-19', :value => local_hostname },
    'local-ipv4' => { :version => '1.0', :value => opts[:local_ip] },
    'mac' => { :version => '2011-01-01', :value => mac },
    "network/interfaces/macs/#{ mac }/device-number" => { :version => '2011-01-01', :value => '0' },
    "network/interfaces/macs/#{ mac }/ipv4-associations/#{ public_ip }" => { :version => '2011-01-01', :value => opts[:local_ip] },
    "network/interfaces/macs/#{ mac }/local-hostname" => { :version => '2011-01-01', :value => local_hostname },
    "network/interfaces/macs/#{ mac }/local-ipv4s" => { :version => '2011-01-01', :value => opts[:local_ip] },
    "network/interfaces/macs/#{ mac }/mac" => { :version => '2011-01-01', :value => mac },
    "network/interfaces/macs/#{ mac }/owner-id" => { :version => '2011-01-01', :value => '123456789012' },
    "network/interfaces/macs/#{ mac }/public-hostname" => { :version => '2011-01-01', :value => public_hostname },
    "network/interfaces/macs/#{ mac }/public-ipv4s" => { :version => '2011-01-01', :value => public_ip },
    "network/interfaces/macs/#{ mac }/security-groups" => { :version => '2011-01-01', :value => 'Security-Group' },
    "network/interfaces/macs/#{ mac }/security-group-ids" => { :version => '2011-01-01', :value => 'sg-12345678' },
    "network/interfaces/macs/#{ mac }/subnet-id" => { :version => '2011-01-01', :value => 'subnet-12345678' },
    "network/interfaces/macs/#{ mac }/subnet-ipv4-cidr-block" => { :version => '2011-01-01', :value => '10.1.2.0/24' },
    "network/interfaces/macs/#{ mac }/vpc-id" => { :version => '2011-01-01', :value => 'vpc-12345678' },
    "network/interfaces/macs/#{ mac }/vpc-ipv4-cidr-block" => { :version => '2011-01-01', :value => 'vpc-12345678' },
    'placement/availability-zone' => { :version => '2008-02-01', :value => 'us-east-1a' },
    'product-codes' => { :version => '2007-03-01' },
    'public-hostname' => { :version => '2007-01-19', :value => public_hostname },
    'public-ipv4' => { :version => '2007-01-19', :value => public_ip },
    'public-keys/0/openssh-key' => { :version => '1.0', :value => 'ssh-rsa AAAAPUBLICKEY admin@workstation' },
    'ramdisk-id' => { :version => '2007-10-10' },
    'reservation-id' => { :version => '1.0', :value => 'r-12345678' },
    'security-groups' => { :version => '1.0', :value => 'sg-12345678' },
    'services/domain' => { :version => '2014-02-25', :value => 'amazonaws.com' },
    'spot/termination-time' => { :version => '2015-01-05' },
  }

  case version
  when '1.0'
    date_version = DateTime.new(2000, 1, 1)
  when 'latest'
    date_version = DateTime.new(3000, 1, 1)
  else
    date_version = DateTime.parse("#{ version }T00:00:00+00:00")
  end

  res = {}

  metadata.each_pair do |key, data|
    case data[:version]
    when '1.0'
      date_current_key = DateTime.new(2000, 1, 1)
    when 'latest'
      date_current_key = DateTime.new(3000, 1, 1)
    else
      date_current_key = DateTime.parse("#{ data[:version] }T00:00:00+00:00")
    end
    if date_version >= date_current_key
      res[key] = data[:value]
    end
  end

  res
end

def parse_request_path(path)
  versions = [
    '1.0',
    '2007-01-19',
    '2007-03-01',
    '2007-08-29',
    '2007-10-10',
    '2007-12-15',
    '2008-02-01',
    '2008-09-01',
    '2009-04-04',
    '2011-01-01',
    '2011-05-01',
    '2012-01-12',
    'latest',
  ]
  _, version, type, key = path.split('/', 4)

  if versions.include?(version) and type == 'meta-data'
    { :version => version, :type => type, :key => key.to_s }
  else
    nil
  end
end

def get_dirs(metadata, key)
  key_size = key.split('/').size
  keys = metadata.keys.map { |k| k if k.match(key) }.compact
  dirs = keys.map { |k| k.split('/')[key_size] }.uniq
  dirs.join("\n")
end

class MetadataWebrick < WEBrick::HTTPServlet::AbstractServlet
  def do_GET request, response
    request_path = parse_request_path(request.path)
    if request_path
      metadata = generate_metadata(request_path[:version], :local_ip => request.remote_ip)
      value = metadata[request_path[:key]]
      if value
        response.status = 200
        response.body = value
      else
        response.status = 200
        response.body = get_dirs(metadata, request_path[:key])
      end
    else
      response.status = 200
    end
    response['Content-Type'] = 'text/plain'
  end
end

server = WEBrick::HTTPServer.new :Port => 80
trap 'INT' do server.shutdown end
server.mount '/', MetadataWebrick
server.start
