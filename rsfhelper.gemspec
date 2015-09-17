Gem::Specification.new do |s|
  s.name = 'rsfhelper'
  s.version = '0.1.0'
  s.summary = 'A client for conveniently sending requests to a Rack-rscript web server'
  s.authors = ['James Robertson']
  s.files = Dir['lib/rsfhelper.rb']
  s.signing_key = '../privatekeys/rsfhelper.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/rsfhelper'
end
