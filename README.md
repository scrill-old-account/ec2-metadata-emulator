EC2 Metadata Emulator
=====================

# Requirements
- Ruby >= 1.9.x

# Usage
* Create alias on `lo0` or `docker0` interface of the host machine:
```
ifconfig docker0:0 169.254.169.254 up
```
* Run the emulator as `root`:
```
sudo [path/to/]ruby ./ec2-metadata-emulator.rb
```

# Facter
* Fix facter 1.x:
```
sed -i "s/\&\& Facter::Util::EC2.can_connect/\|\| Facter::Util::EC2.can_connect/" /usr/lib/ruby/vendor_ruby/facter/ec2.rb
```
* Fix facter 2.x:
```
sed -i "s/kvm/kvm\|docker/g" /usr/lib/ruby/vendor_ruby/facter/ec2.rb
```

# Ohai
* Fix:
```
sed -i "s/has_ec2_mac? && //" /usr/lib/ruby/vendor_ruby/ohai/plugins/ec2.rb
```
