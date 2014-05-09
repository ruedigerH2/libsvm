CXX ?= g++
CFLAGS = -Wall -Wconversion -Wno-sign-conversion -O3 -fPIC 
SHVER = 3.1.8
OS = $(shell uname)

all: svm-train svm-predict svm-scale

lib: svm.o
	@echo "Building library"
    ifeq ($(OS),Darwin)
        # Clang is default compiler on 10.9
        ifeq ($(shell sw_vers | grep -o 10.9),10.9)
			@$(CXX) -dynamiclib -Wl,-install_name,/usr/local/lib/libsvm/libsvm.$(SHVER).dylib svm.cpp -current_version $(SHVER) -compatibility_version 1.0 -fvisibility=hidden -o libsvm.$(SHVER).dylib
            #@install_name_tool -change libsvm.$(SHVER).dylib /usr/local/lib/libsvm/libsvm.$(SHVER).dylib   libsvm.$(SHVER).dylib
            #libtool -dynamic svm.o -o libsvm.$(SHVER).dylib -current_version 1.0 -compatibility_version 1.0
        else
			@SHARED_LIB_FLAG="-dynamiclib -Wl,-install_name,/usr/local/lib/libsvm/libsvm.$(SHVER).dylib";
			@$(CXX) $${SHARED_LIB_FLAG} svm.o -o libsvm.$(SHVER).dylib
        endif
    else 
		@SHARED_LIB_FLAG="-shared -Wl,-soname,libsvm.so.$(SHVER)";
		@$(CXX) $${SHARED_LIB_FLAG} svm.o -o libsvm.so.$(SHVER)
    endif

svm-predict: svm-predict.c svm.o
	@echo "Building svm-predict"
	@$(CXX) $(CFLAGS) svm-predict.c svm.o -o svm-predict -lm

svm-train: svm-train.c svm.o
	@echo "Building svm-train"
	@$(CXX) $(CFLAGS) svm-train.c svm.o -o svm-train -lm

svm-scale: svm-scale.c
	@echo "Building svm-scale"
	@$(CXX) $(CFLAGS) svm-scale.c -o svm-scale

svm.o: svm.cpp svm.h
	@echo "Building svm"
	@$(CXX) $(CFLAGS) -c svm.cpp

clean:
	@echo "Cleaning"
	@rm -f *~ svm.o svm-train svm-predict svm-scale libsvm.so.$(SHVER)
ifeq ($(OS),Darwin)
	@rm -f *~ libsvm.$(SHVER).dylib libsvm.dylib
else 
	@rm -f *~ libsvm.so.$(SHVER) libsvm.so
endif

install:
	@echo "Installing"
	@mkdir /usr/local/lib/libsvm
	@mkdir /usr/local/include/libsvm
    ifeq ($(OS),Darwin)
		@cp libsvm.$(SHVER).dylib /usr/local/lib/libsvm
		@ln -s /usr/local/lib/libsvm/libsvm.$(SHVER).dylib /usr/local/lib/libsvm/libsvm.dylib
		@cp svm.h /usr/local/include/libsvm
    else 
		@cp libsvm.so.$(SHVER) /usr/local/lib/libsvm
		@ln -s /usr/local/lib/libsvm/libsvm.so.$(SHVER) /usr/local/lib/libsvm/libsvm.so
		@cp svm.h /usr/local/include/libsvm
    endif

uninstall:
	@echo "Uninstalling"
	@rm -fr /usr/local/lib/libsvm
	@rm -fr /usr/local/include/libsvm

