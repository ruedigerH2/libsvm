CXX ?= g++
CFLAGS = -Wall -Wconversion -Wno-sign-conversion -O3 -fPIC 
SHVER = 3
OS = $(shell uname)

all: svm-train svm-predict svm-scale

lib: svm.o
	@echo "Building library"
    ifeq ($(OS),Darwin)
        # Clang is default compiler on 10.9
        ifeq ($(shell sw_vers | grep -o 10.9),10.9)
			@$(CXX) -dynamiclib svm.cpp -current_version 1.0 -compatibility_version 1.0 -fvisibility=hidden -o libsvm.$(SHVER).dylib
            #ln -s libsvm.$(SHVER).dylib libsvm.dylib
            #libtool -dynamic svm.o -o libsvm.$(SHVER).dylib -current_version 1.0 -compatibility_version 1.0
        else
			@SHARED_LIB_FLAG="-dynamiclib -Wl,-install_name,libsvm.$(SHVER).dylib";
			@$(CXX) $${SHARED_LIB_FLAG} svm.o -o libsvm.$(SHVER).dylib
            #ln -s libsvm.$(SHVER).dylib libsvm.dylib
        endif
		
        # Create a symlink to the versioned library
		@ln -s libsvm.$(SHVER).dylib libsvm.dylib
		
    else 
		@SHARED_LIB_FLAG="-shared -Wl,-soname,libsvm.so.$(SHVER)";
		@$(CXX) $${SHARED_LIB_FLAG} svm.o -o libsvm.so.$(SHVER)
		
        # Create a symlink to the versioned library
		@ln -s libsvm.so.$(SHVER) libsvm.so
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