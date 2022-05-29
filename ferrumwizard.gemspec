Gem::Specification.new do |s|
  s.name = 'ferrumwizard'
  s.version = '0.3.3'
  s.summary = 'Makes web scraping easier using the Ferrum gem.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/ferrumwizard.rb']
  s.add_runtime_dependency('ferrum', '~> 0.11', '>=0.11')
  s.add_runtime_dependency('rxfhelper', '~> 1.5', '>=1.5.2')
  s.signing_key = '../privatekeys/ferrumwizard.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/ferrumwizard'
end
