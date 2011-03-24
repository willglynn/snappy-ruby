# Determine our own version
VERSION_HEADER = File.join(File.dirname(__FILE__), 'ext', 'snappy', 'version.h')
MY_GEM_VERSION = File.read(VERSION_HEADER) =~ /GEM_VERSION "(.*)"/ && $1
SNAPPY_VERSION = File.read(VERSION_HEADER) =~ /SNAPPY_VERSION "(.*)"/ && $1

VENDOR_DIR = File.join(File.dirname(__FILE__), 'ext', 'snappy', 'vendor')
Dir.mkdir(VENDOR_DIR) unless File.exists?(VENDOR_DIR)

# Determine Snappy's version and path
SNAPPY_DIR = File.join(VENDOR_DIR, "snappy-#{SNAPPY_VERSION}")

# Download and unpack Snappy if needed
unless File.exists?(SNAPPY_DIR)
  old_pwd = Dir.pwd
  archive = "#{File.basename SNAPPY_DIR}.tar.gz"
  
  begin
    Dir.chdir(File.dirname(SNAPPY_DIR))
    puts "Downloading and unpacking #{File.basename SNAPPY_DIR}..."
    system "curl", "http://snappy.googlecode.com/files/snappy-#{SNAPPY_VERSION}.tar.gz", "-o", archive
    system "tar", "xzf", archive
    
  ensure
    File.unlink(archive) if File.exists?(archive)
    Dir.chdir(old_pwd)
  end
end

Gem::Specification.new do |s|
  s.name = 'snappy_ext'

  s.version  = MY_GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.summary  = 'C extension for the Snappy compression algorithm.'
  s.description = "C extension to to bring the Snappy compression library to Ruby. Google's C++ implementation (version #{SNAPPY_VERSION}) is statically linked into this extension, resulting in no runtime dependencies."

  s.require_paths = ['ext']
  
  %w(
    snappy_ext.gemspec
    ext/snappy/*.cc
    ext/snappy/*.h
    ext/snappy/*.rb
    ext/snappy/vendor/snappy-*/*
    ext/snappy/vendor/snappy-*/m4/*
  ).each { |spec|
    s.files += Dir[spec].select { |fn| File.file?(fn) }
  }

  s.has_rdoc = false
  s.extensions << 'ext/snappy/extconf.rb'

  s.author = 'Will Glynn'
  s.email = 'will@willglynn.com'
  s.homepage = 'http://github.com/delta407/snappy-ruby'

  # s.add_dependency 'snappy', "=#{MY_GEM_VERSION}"
end
