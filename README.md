# Gen-CSR
Small script to generate certificate requests with altdns names (which is painful to do in most other tools I've seen)

## Installation
Script requires ruby installed with openssl-support, this is often a seperate package in many linux distributions (libruby-openssl or ruby-openssl).

## Usage
```
shell> gen-csr.rb -h
Usage: gen-csr.rb [options]
    -c, --config CONFIG              Load defaults from specified YAML config-file. (Default: /etc/gen-csr.conf)
    -n, --name DNSNAME               DNS-names to add to certificate, first will also be used for common-name
    -s, --keysize SIZE               Keysize for private key (Default: 2048)
    -o, --output-path DIRECTORY      Path to write certificate + key (defaults to ~/csr)
    -w, --add-www                    Prefix www.* to names
```

## Examples

### Generate CSR for mydomain.com (include .www) and IP-Address
```
gen-csr.rb --name mydomain.com --add-www --ip 172.16.32.48
```

### Generate certificate with alt-name for mydomain.no and www.mydomain.no

```
gen-csr.rb --name mydomain.com --add-www
```

### Generate certificate for domain1.com and domain2.com
```
gen-csr.rb --name domain1.com --name domain2.com
```

### Generate a bunch of CSRs for different devices
```
shell> for i in router1 router2 router3; do gen-csr.rb --name $i.internal; done
```

### Docker support
```
cp gen-csr.conf.example gen-csr.conf
docker build -t gen-csr .
docker run --rm gen-csr --name myapp.preview.rocks -o > csr.out
cat csr.out
```
