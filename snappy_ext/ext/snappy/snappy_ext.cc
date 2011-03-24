#include <snappy.h>
#include "version.h"

#include "ruby.h"

#if HAVE_RUBY_ST_H
#include "ruby/st.h"
#endif
#if HAVE_ST_H
#include "st.h"
#endif

#include <string.h>
#include <stdio.h>

#ifdef HAVE_RUBY_ENCODING_H
#include <ruby/encoding.h>
int binary_string_encoding;
#endif

VALUE binary_string_for_buffer(VALUE input, char * buf, size_t len)
{
  // Create the string
  VALUE str = rb_str_new5(input, buf, len);
  
#ifdef HAVE_RUBY_ENCODING_H
  // Set the encoding
  rb_enc_associate_index(str, binary_string_encoding);
#endif
  
  // Copy taintedness
  OBJ_INFECT(input, str);
  
  return str;
}

/*
 * call-seq:
 *   compress(string) -> string
 *
 * returns a Snappy-compressed string
 */
extern "C"
VALUE snappy_ext_compress(VALUE self, VALUE string)
{
  string = StringValue(string);

  char * in_buf = RSTRING_PTR(string);
  size_t in_len = RSTRING_LEN(string);
  
  char * out_buf = (char *)malloc(snappy::MaxCompressedLength(in_len));
  size_t out_len = 0;
    
  snappy::RawCompress(in_buf, in_len, out_buf, &out_len);
  
  // Shrink the buffer
  out_buf = (char *)realloc(out_buf, out_len);
  
  // Encase the output buffer in a String object without copying
  return binary_string_for_buffer(string, out_buf, out_len);
}

/*
 * call-seq:
 *   uncompress(string) -> string
 *
 * Returns a decompressed string, or raises ArgumentError if the compressed
 * data is somehow corrupt
 */
extern "C"
VALUE snappy_ext_uncompress(VALUE self, VALUE string)
{
  string = StringValue(string);

  char * in_buf = RSTRING_PTR(string);
  size_t in_len = RSTRING_LEN(string);

  size_t out_len = 0;

  if (!snappy::GetUncompressedLength(in_buf, in_len, &out_len)) {
    rb_raise(rb_eArgError, "invalid compressed data");
  }
  
  char * out_buf = (char*)malloc(out_len);
  
  if (!snappy::RawUncompress(in_buf, in_len, out_buf)) {
    free(out_buf);
    rb_raise(rb_eArgError, "invalid compressed data");
  }
  
  return binary_string_for_buffer(string, out_buf, out_len);
}

extern "C"
void Init_snappy_ext()
{
  VALUE snappy_sym, snappy, snappy_ext;
  
  snappy_sym = rb_intern("Snappy");
  
#ifdef HAVE_RUBY_ENCODING_H
  // Look up the BINARY encoding
  binary_string_encoding = rb_enc_find_index("BINARY");
#endif
  
  // Get or define ::Snappy
  if (rb_const_defined(rb_cObject, snappy_sym)) {
    snappy = rb_const_get(rb_cObject, rb_intern("Snappy"));
  } else {
    snappy = rb_define_module("Snappy");
  }
  
  // Define Snappy::Ext
  snappy_ext = rb_define_module_under(snappy, "Ext");
  
  // Pass in our version constants
  rb_define_const(snappy_ext, "Version", rb_str_new2(GEM_VERSION));
  {
    char version[16];
    snprintf(version, sizeof(version), "%u.%u.%u",
      SNAPPY_VERSION >> 16 & 0xff, SNAPPY_VERSION >> 8 & 0xff, SNAPPY_VERSION & 0xff
      );
    rb_define_const(snappy_ext, "SnappyVersion", rb_str_new2(version));
  }
  
  // Add our methods to both Snappy::Ext and Snappy
  rb_define_module_function(snappy, "compress", RUBY_METHOD_FUNC(snappy_ext_compress), 1);
  rb_define_module_function(snappy, "uncompress", RUBY_METHOD_FUNC(snappy_ext_uncompress), 1);
  rb_define_module_function(snappy_ext, "compress", RUBY_METHOD_FUNC(snappy_ext_compress), 1);
  rb_define_module_function(snappy_ext, "uncompress", RUBY_METHOD_FUNC(snappy_ext_uncompress), 1);
}
