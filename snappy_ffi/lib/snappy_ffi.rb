require 'rubygems'
require 'ffi'

#:nodoc
module Snappy; end

module Snappy::FFI
  Version = "0.1.1"
  
  #:nodoc
  module Snappy::FFI::Lib
    extend FFI::Library

    # Find the library in the normal places, or the file specified by SNAPPY_LIB if set
    paths =
      Array(
        ENV['SNAPPY_LIB'] ||
        Dir['/{opt,usr}/{,local/}lib{,64}/libsnappy.{dylib,so*}']
        )
    begin
      ffi_lib(*paths)
    rescue LoadError
      raise LoadError,
        "didn't find libsnappy on your system. " +
        "Please install (http://code.google.com/p/snappy/)"
    end
    
    # What should we look for?
    ExportSets = [
      {
        :description => "g++ 4",
        :max_compressed_length => '_ZN6snappy19MaxCompressedLengthEm',
        :get_uncompressed_length => '_ZN6snappy21GetUncompressedLengthEPKcmPm',
        :raw_compress => '_ZN6snappy11RawCompressEPKcmPcPm',
        :raw_uncompress => '_ZN6snappy13RawUncompressEPKcmPc'
      }
    ]
    
    # Let you add extra entries to this list without hacking at this file
    if Snappy::FFI.const_defined?(:LocalExportSet)
      ExportSets << Snappy::FFI::LocalExportSet
    end
    
    # Walk FunctionSets until we find something that works
    libsnappy = ffi_libraries.first
    ChosenExportSet = ExportSets.find { |set|
      libsnappy.find_function(set[:max_compressed_length])
    }
    
    if ChosenExportSet.nil?
      raise LoadError, "snappy_ffi couldn't identify your libsnappy's function exports. " +
        "You'll need to determine what these functions are called, then tell Snappy::FFI. " +
        "Please see http://github.com/delta407/snappy-ruby/ for more information."
    end
    
    attach_function :max_compressed_length, ChosenExportSet[:max_compressed_length],
      [:size_t], :size_t
    attach_function :get_uncompressed_length, ChosenExportSet[:get_uncompressed_length],
      [:buffer_in, :size_t, :pointer], :bool
    attach_function :raw_compress, ChosenExportSet[:raw_compress],
      [:buffer_in, :size_t, :buffer_out, :pointer], :void
    attach_function :raw_uncompress, ChosenExportSet[:raw_uncompress],
      [:buffer_in, :size_t, :buffer_out], :bool

    # We deal in *size_t quite a lot
    # Make it a struct, so it's easy to convert from pointers to values and back
    class SizeT < FFI::Struct
      layout :value, :size_t
    end
  end

  # Compresses a string, returning the compressed value
  def self.compress(input)
    # Set up our input
    input = input.to_s
    input_size = input.bytesize rescue input.size
    
    # Make a place to record our compressed size
    output_size = Lib::SizeT.new
    
    # Make a buffer big enough to hold the worst case
    max = Lib.max_compressed_length(input_size)
    FFI::MemoryPointer.new(max) { |output_buffer|
      # Compress
      Lib.raw_compress(input, input_size, output_buffer, output_size.pointer)

      # Get our string
      output = output_buffer.get_bytes(0, output_size[:value])

      # Return, copying taint as needed
      if input.tainted?
        return output.taint
      else
        return output
      end
    }
  end
  
  # Decompresses a string, throwing ArgumentError if it's somehow corrupt
  def self.uncompress(input)
    # Set up our input
    input = input.to_s
    input_size = input.bytesize rescue input.size
        
    # Make a place to record our uncompressed size
    output_size = Lib::SizeT.new
    
    # See how big our output will be
    if !Lib.get_uncompressed_length(input, input_size, output_size.pointer)
      # failure!
      raise ArgumentError, "invalid compressed data"
    end
    
    # Make the buffer
    FFI::MemoryPointer.new(output_size[:value]) { |output_buffer|
      # Decompress
      if !Lib.raw_uncompress(input, input_size, output_buffer)
        raise ArgumentError, "invalid compressed data"
      end
    
      # Get our string
      output = output_buffer.get_bytes(0, output_size[:value])
    
      # Return, copying taint as needed
      if input.tainted?
        return output.taint
      else
        return output
      end    
    }
  end
  
end
