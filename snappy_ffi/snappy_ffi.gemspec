require File.expand_path('../lib/snappy_ffi', __FILE__)

Gem::Specification.new do |s|
  s.name = 'snappy_ffi'

  s.version  = Snappy::FFI::Version
  s.platform = Gem::Platform::RUBY
  s.summary  = 'FFI extension for libsnappy.'
  s.description = "FFI extension to to bring the Snappy compression library to Ruby. libsnappy must be installed."

  s.require_paths = ['lib']
  
  %w(
    snappy_ext.gemspec
    lib/snappy_ffi.rb
  ).each { |spec|
    s.files += Dir[spec].select { |fn| File.file?(fn) }
  }

  s.has_rdoc = false

  s.author = 'Will Glynn'
  s.email = 'will@willglynn.com'
  s.homepage = 'http://github.com/delta407/snappy-ruby'

  s.add_dependency 'ffi'
  s.add_dependency 'snappy', '=0.1.1'
  s.requirements << "libsnappy"
end
