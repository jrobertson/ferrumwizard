Gem::Specification.new do |s|
  s.name = 'ferrumwizard'
  s.version = '0.1.2'
  s.summary = 'Makes web scraping easier using the Ferrum gem.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/ferrumwizard.rb']
  s.add_runtime_dependency('rexle', '~> 1.5', '>=1.5.7')  
  s.add_runtime_dependency('ferrum', '~> 0.9', '>=0.9.0')  
  s.signing_key = '../privatekeys/ferrumwizard.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/ferrumwizard'
end
