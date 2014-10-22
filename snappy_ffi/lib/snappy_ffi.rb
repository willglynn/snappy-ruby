require 'rubygems'
require 'ffi'

#:nodoc
module Snappy; end

module Snappy::FFI
  Version = "0.1.3"
  
  #:nodoc
  module Snappy::FFI::Lib
    extend FFI::Library

    ffi_lib 'snappy'

    enum :snappy_status, [:ok, :invalid_input, :too_small]

    attach_function :max_compressed_length, :snappy_max_compressed_length,
      [:size_t], :size_t
    attach_function :get_uncompressed_length, :snappy_uncompressed_length,
      [:buffer_in, :size_t, :pointer], :snappy_status
    attach_function :raw_compress, :snappy_compress,
      [:buffer_in, :size_t, :buffer_out, :pointer], :snappy_status
    attach_function :raw_uncompress, :snappy_uncompress,
      [:buffer_in, :size_t, :buffer_out, :pointer], :snappy_status

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
    output_size[:value] = max = Lib.max_compressed_length(input_size)
    FFI::MemoryPointer.new(max) { |output_buffer|
      # Compress
      status = Lib.raw_compress(input, input_size, output_buffer, output_size.pointer)
      raise ArgumentError, status if status != :ok

      # Get our string
      output = output_buffer.get_bytes 0, output_size[:value]

      # Return, copying taint as needed
      output.taint if input.tainted?
      return output
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
    status = Lib.get_uncompressed_length(input, input_size, output_size.pointer)
    raise ArgumentError, status if status != :ok

    # Make the buffer
    FFI::MemoryPointer.new(output_size[:value]) { |output_buffer|
      # Decompress
      status = Lib.raw_uncompress(input, input_size, output_buffer, output_size)
      raise ArgumentError, status if status != :ok

      # Get our string
      output = output_buffer.get_bytes(0, output_size[:value])
    
      # Return, copying taint as needed
      output.taint if input.tainted?
      return output 
    }
  end
end

module Snappy
  def self.compress(string); Snappy::FFI.compress(string) end
  def self.uncompress(string); Snappy::FFI.uncompress(string) end
end
