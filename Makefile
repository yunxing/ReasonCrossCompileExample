OCAMLDEP=ocamldep
BUILDDIR=_build
SRCDIR=src
CAML_INIT=_build/stub/init.o

EXTDLL:=.o

$(shell mkdir -p _build _build/stub _build/$(SRCDIR) _build/test)

GENERATOR_FILES=_build/stub/bindings.re

# The files used to build the stub generator.
LIBFILES=_build/stub/bindings.cmx _build/stub/hello.o

SOURCES := $(shell find $(SRCDIR) -name '*.re')

SOURCES_IN_BUILD := $(addprefix _build/,$(SOURCES))

MODULES=Hello

CMXS=$(addsuffix .cmx,$(MODULES))

CMXS_IN_BUILD=$(addprefix _build/src/,$(CMXS))

TOOLCHAIN=-toolchain android

all: sharedlib

android: _build/libhello.o

_build/%.re: %.re
	mkdir -p $(dir $@)
	cp $< $@

_build/%.ml: %.ml
	mkdir -p $(dir $@)
	cp $< $@

_build/%.re: %.ml
	refmt -print re -parse ml $< > $@

%.cmx: %.re $(SOURCES_IN_BUILD)
	ocamlfind $(TOOLCHAIN) opt -ccopt -fPIC -thread -w -40 -pp 'refmt --print binary' -c -o $@ -I _build/src -impl $<

_build/%.o: %.c
	ocamlfind $(TOOLCHAIN) opt -ccopt -fPIC -ccopt -std=c11 -c $< -o $@
	mkdir -p $(dir $@)
	mv $(notdir $@) $@

_build/libhello.o: $(CMXS_IN_BUILD) $(LIBFILES)
	ocamlfind $(TOOLCHAIN) opt -ccopt -fno-omit-frame-pointer -ccopt -fPIC -ccopt -O3 -o _build/libhello.o -linkpkg -output-complete-obj -linkall -runtime-variant _pic -output-obj -verbose $^

android-armv7: clean android
	$(ANDROID_NDK)/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ar rc _build/libhello.a _build/libhello.o
	$(ANDROID_NDK)/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ranlib _build/libhello.a
	@echo "lib genereated at: _build/libhello.a"
	@echo "lib type:"
	@file _build/libhello.a

android-x86: clean android
	$(ANDROID_NDK)/toolchains/x86-4.9/prebuilt/linux-x86_64/bin/i686-linux-android-ar rc _build/libhello.a _build/libhello.o
	$(ANDROID_NDK)/toolchains/x86-4.9/prebuilt/linux-x86_64/bin/i686-linux-android-ranlib _build/libhello.a
	@echo "lib genereated at: _build/libhello.a"
	@echo "lib type:"
	@file _build/libhello.a

clean:
	rm -rf _build
