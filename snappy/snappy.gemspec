Gem::Specification.new do |s|
  s.name = 'snappy'

  s.version  = '0.1.3'
  s.platform = Gem::Platform::RUBY
  s.summary  = "Snappy is a fast compression/decompression library written by Google."
  s.description = "Provides compression that's much faster than zlib, but doesn't compress nearly as well. Requires either snappy_ext or snappy_ffi to do the actual compression."

  s.require_paths = ['lib']
  
  %w(
    snappy.gemspec
    lib/snappy.rb
  ).each { |spec|
    s.files += Dir[spec].select { |fn| File.file?(fn) }
  }

  s.has_rdoc = false

  s.author = 'Will Glynn'
  s.email = 'will@willglynn.com'
  s.homepage = 'http://github.com/willglynn/snappy-ruby'
  
  s.requirements << "either snappy_ext or snappy_ffi"
end
