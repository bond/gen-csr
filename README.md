# Gen-CSR
Small script to generate certificate requests with altdns names (which is painful to do in most other tools I've seen)

## Installation
Script requires ruby installed with openssl-support, this is often a seperate package in many linux distributions (libruby-openssl or ruby-openssl).

## Examples

Generate certificate with alt-name for mydomain.no and www.mydomain.no

```
gen-csr.rb --name mydomain.com --add-www
```

Generate certificate for domain1.com and domain2.com
```
gen-csr.rb --name domain1.com --name domain2.com
```
