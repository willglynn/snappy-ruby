snappy-ruby
===========

This repository contains a set of Ruby gems, collectively exposing the Snappy
compression algorithm to Ruby, a fast compressor/decompressor.

About Snappy
------------

From the [official Snappy website](http://code.google.com/p/snappy/):

> Snappy is a compression/decompression library. It does not aim for maximum
> compression, or compatibility with any other compression library; instead, it
> aims for very high speeds and reasonable compression. For instance, compared
> to the fastest mode of zlib, Snappy is an order of magnitude faster for most
> inputs, but the resulting compressed files are anywhere from 20% to 100%
> bigger. On a single core of a Core i7 processor in 64-bit mode, Snappy
> compresses at about 250 MB/sec or more and decompresses at about 500 MB/sec
> or more.
> 
> Snappy is widely used inside Google, in everything from BigTable and MapReduce
> to our internal RPC systems. (Snappy has previously been referred to as "Zippy"
> in some presentations and the likes.)

Example
-------

    $ gem install snappy_ext
    Building native extensions.  This could take a while...
    <snip>
    
    $ irb -rubygems -rsnappy_ext
    >> Snappy.compress "1234567890" * 10
    => "d$1234567890\376\n\000f\n\000"
    
    >> Snappy::Ext.uncompress "d$1234567890\376\n\000f\n\000"
    => "1234567890123456789012345678901234567890...
    
Ruby Gems
---------

I have made two bindings for Snappy:

- `snappy_ext`

  A C extension that builds and links libsnappy into itself as part of the
  install process.

- `snappy_ffi`

  Uses FFI to communicate with libsnappy, which must be installed separately.
  Works on non-MRI Ruby implementations.

Put `snappy_ext` or `snappy_ffi` in your Gemfile as appropriate, but use the
Snappy functions (instead of Snappy::Ext or Snappy::FFI) so you can change
your mind later.

snappy_ext
----------

This gem compiles libsnappy into a C Ruby extension, resulting in no external
dependencies. However, this doesn't work at all on most non-MRI Ruby
interpreters, and the build process is kind of... unusual, so it will probably
break horribly on different platforms or when cross-compliling.

If it works for you, great. (And it seems to work on recent Linux distros and
MacOSX.) If it doesn't, please use `snappy_ffi`, or tinker with it and send up
a patch. `mkmf` is dark magic, well beyond my powers. I probably can't help.

snappy_ffi
----------

This gem relies on having a libsnappy dynamic library on the host machine.

`snappy_ffi` is sort of a good news/bad news situation. Bad news is, libsnappy
has only a C++ interface, and C++ resists efforts to use it without a C++
compiler. Good news is, Google was kind enough to expose an interface that
hides exceptions and can operate on caller-allocated buffers, so it's possible
to use from FFI.

The last C++ hurdle is that `snappy::MaxCompressedLength()` will be exported
by libsnappy as something like `__ZN6snappy19MaxCompressedLengthEm`, and the
way the names are transformed varies from compiler to compiler.

To address this, `snappy_ffi` maintains a list of identifiers it's encountered
in the wild, and attempts to automatically detect whatever library is installed
on your system. This works great on recent versions of Linux and OSX using the
standard toolchain.

That said, if you're using a different compiler or on a weird architecture,
`snappy_ffi` might not know what's going on. If that happens, you will get an
error message to that effect. You'll need to do some platform-specific
investigation to determine what the needed functions are called on your
platform. A general process might be:

1. Find the libsnappy library on your system
2. Get a list of exported symbols, using whatever tool your OS provides
3. From this list, find four functions: MaxCompressedLength, RawCompress,
   GetUncompressedLength, RawUncompress. Two of them have pointer and "Source"
   versions. We need the pointer versions, so ignore anything that says "Source".
4. Define a Ruby hash encoding your findings before loading snappy_ffi.

You'll want to do something like:

    module Snappy
      module FFI
        LocalExportSet = {
          :max_compressed_length => '_ZN6snappy19MaxCompressedLengthEm',
          :get_uncompressed_length => '_ZN6snappy21GetUncompressedLengthEPKcmPm',
          :raw_compress => '_ZN6snappy11RawCompressEPKcmPcPm',
          :raw_uncompress => '_ZN6snappy13RawUncompressEPKcmPc'
        }
      end
    end
    
    require 'snappy_ffi'

Open a GitHub issue too! Include your hash and your platform/compiler details. 
That way, we can get your data included in the list of things to try by
default.
