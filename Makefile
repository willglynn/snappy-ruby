SUBDIRS=snappy snappy_ext snappy_ffi

all:
	@for i in $(SUBDIRS); do (cd $$i; echo "building $$i"; gem build *.gemspec; mv *.gem ..); done

clean:
	-rm *.gem

