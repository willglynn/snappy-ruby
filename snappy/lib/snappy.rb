# Load snappy_ext or snappy_ffi, as appropriate
begin
  require 'snappy_ext'

rescue LoadError => snappy_ext
  
  begin
    require 'snappy_ffi'

  rescue LoadError => snappy_ffi
    raise LoadError, [
        "snappy couldn't load snappy_ext or snappy_ffi. Please install one. Specifically:",
        "snappy_ext failed: #{snappy_ext}",
        "snappy_ffi failed: #{snappy_ffi}"
      ].join("\n")
  end
end

module Snappy
  
  # Choose a concrete implementation for compress and uncompress
  Implementation = (const_defined?(:Ext) ? Snappy::Ext : Snappy::FFI)
  
  class << self
    # Pull in our selected implementation
    include Implementation
    
    # Ensure compress and uncompress are accessible
    public :compress
    public :uncompress

    # Decompress seems like a reasonable synonym to suport
    alias_method :decompress, :uncompress

    # Make it smell like zlib, too, because hey, why not?
    alias_method :inflate, :uncompress
    alias_method :deflate, :compress
  end
  
end