ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

#where to install mosquitto:
#$(INSTALL_ROOT_$(OS)) is pointing to $QNX_TARGET
#by default, unless it was manually re-routed to
#a staging area by setting both INSTALL_ROOT_nto
#and USE_INSTALL_ROOT
MOSQUITTO_INSTALL_ROOT ?= $(INSTALL_ROOT_$(OS))

#choose Release or Debug
CMAKE_BUILD_TYPE ?= Release

#set the following to FALSE if generating .pinfo files is causing problems
GENERATE_PINFO_FILES ?= TRUE

#override 'all' target to bypass the default QNX build system
ALL_DEPENDENCIES = mosquitto_all
.PHONY: mosquitto_all

FLAGS   += -g -D_QNX_SOURCE
LDFLAGS += -Wl,--build-id=md5 -lang-c++ -lsocket

CMAKE_ARGS = -DCMAKE_TOOLCHAIN_FILE=$(PROJECT_ROOT)/qnx.nto.toolchain.cmake \
			 -DCMAKE_INSTALL_PREFIX=$(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr \
			 -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
			 -DCMAKE_INSTALL_BINDIR=$(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin \
			 -DCMAKE_INSTALL_INCLUDEDIR=$(MOSQUITTO_INSTALL_ROOT)/usr/include \
			 -DCMAKE_INSTALL_LIBDIR=$(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/lib \
			 -DCMAKE_INSTALL_SBINDIR=$(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/sbin \
			 -DCMAKE_MODULE_PATH=$(PROJECT_ROOT)/../ \
			 -DEXTRA_CMAKE_C_FLAGS="$(FLAGS)" \
			 -DEXTRA_CMAKE_CXX_FLAGS="$(FLAGS)" \
			 -DEXTRA_CMAKE_LINKER_FLAGS="$(LDFLAGS)" \
			 -DGCC_VER=${GCC_VER} \
			 -DWITH_BRIDGE=OFF \
			 -DINC_BRIDGE_SUPPORT=OFF \
			 -DDOCUMENTATION=OFF

MAKE_ARGS ?= -j $(firstword $(JLEVEL) 4)

define PINFO
endef
PINFO_STATE=Experimental
USEFILE=

include $(MKFILES_ROOT)/qtargets.mk

ifndef NO_TARGET_OVERRIDE
mosquitto_all:
	@mkdir -p build
	@cd build && cmake $(CMAKE_ARGS) ../../../../../
	@cd build && make all $(MAKE_ARGS) VERBOSE=1

install: mosquitto_all
	@cd build && make install $(MAKE_ARGS)
	@cp -r $(PROJECT_ROOT)/../test ./build
	@cd build/test/broker/c && make -f Makefile.qnx clean && make -f Makefile.qnx $(MAKE_ARGS) TARGET=$(MOSQUITTO_INSTALL_ROOT) CPUVARDIR=$(CPUVARDIR)
	@cd build/test/lib/c && make -f Makefile.qnx clean&& make -f Makefile.qnx $(MAKE_ARGS) TARGET=$(MOSQUITTO_INSTALL_ROOT) CPUVARDIR=$(CPUVARDIR)
	@cd build/test/lib/cpp && make -f Makefile.qnx clean && make -f Makefile.qnx $(MAKE_ARGS) TARGET=$(MOSQUITTO_INSTALL_ROOT) CPUVARDIR=$(CPUVARDIR)
	@mkdir -p $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/client
	@cp $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mosquitto_pub $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/client
	@cp $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mosquitto_sub $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/client
	@cp $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mosquitto_rr $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/client
	@mkdir -p $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/src
	@cp $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/sbin/mosquitto $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/src
	@cp -r build/test $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/broker/c/*.c
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/broker/c/*.h
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/broker/c/Makefile*
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/broker/Makefile*
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/client/Makefile*
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/lib/c/*.c
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/lib/cpp/*.cpp
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/lib/c/Makefile*
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/lib/Makefile*
	@rm -rf $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/old
	@rm -rf $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/random
	@rm -rf $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/unit
	@rm $(MOSQUITTO_INSTALL_ROOT)/$(CPUVARDIR)/usr/bin/mqtt_tests/test/Makefile*
clean iclean spotless:
	@rm -fr build

cuninstall uninstall:

endif

#everything down below deals with the generation of the PINFO
#information for shared objects that is used by the QNX build
#infrastructure to embed metadata in the .so files, for example
#data and time, version number, description, etc. Metadata can
#be retrieved on the target by typing 'use -i <path to mosquitto .so file>'.
#this is optional: setting GENERATE_PINFO_FILES to FALSE will disable
#the insertion of metadata in .so files.
ifeq ($(GENERATE_PINFO_FILES), TRUE)
#the following rules are called by the cmake generated makefiles,
#in order to generate the .pinfo files for the shared libraries
%.so.2.0.15:
	$(ADD_PINFO)
	$(ADD_USAGE)

endif
