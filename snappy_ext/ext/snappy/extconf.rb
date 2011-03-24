require 'mkmf'

# Compile the embedded snappy- lib
vendor_dir = File.join(File.dirname(__FILE__)), "vendor"
snappy_dir = Dir[File.join(vendor_dir, "snappy-*")].first
old_pwd = Dir.pwd
begin
  Dir.chdir(snappy_dir)
  
  fork {
    exec("./configure")
  }; Process.wait; exit(1) unless $?.success?
  fork {
    exec("make")
  }; Process.wait; exit(1) unless $?.success?
  
ensure
  Dir.chdir(old_pwd)
end

have_header("ruby/st.h") || have_header("st.h")

# Pull in Snappy includes
$INCFLAGS << " -I#{snappy_dir}"

# Link with the Snappy object files
Dir["#{snappy_dir}/.libs/*.o"].each { |o|
  $LOCAL_LIBS << " #{o}"
}

# Ensure we're linked with CXX, or it all breaks, due to libstdc++ and such
#CONFIG['LDSHARED'] = '$(CXX) -dynamiclib'

have_library("stdc++")
dir_config('snappy')
create_makefile('snappy_ext')
