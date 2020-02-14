FROM ruby

ADD gen-csr.rb /usr/local/bin
RUN chmod +x /usr/local/bin/gen-csr.rb

ENTRYPOINT ["gen-csr.rb"]
