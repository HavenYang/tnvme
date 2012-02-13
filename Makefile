# Copyright (c) 2011, Intel Corporation.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# Compiling tnvme requires the boost libraries to be installed
# Ubuntu: sudo apt-get install libboost1.42-all-dev
CC = g++
CFLAGS = -g -O0 -W -Wall -Werror -DDEBUG
APP_NAME = tnvme
LDFLAGS = $(foreach stem, $(SUBDIRS),./$(stem)/lib$(stem).a)
LDFLAGS += -lboost_filesystem
INCLUDES = -I./ -I../

SUBDIRS:=			\
	Singletons		\
	GrpInformative		\
	GrpPciRegisters		\
	GrpCtrlRegisters	\
	GrpBasicInit		\
	GrpResets		\
	GrpNVMReadCmd		\
	Queues			\
	Cmds			\
	Utils

SOURCES:=			\
	globals.cpp		\
	group.cpp		\
	test.cpp		\
	testDescribe.cpp	\
	tnvme.cpp		\
	tnvmeHelpers.cpp	\
	trackable.cpp

#
# RPM build parameters
#
RPMBASE=tnvme
MAJOR=$(shell awk 'FNR==27' version.h)
MINOR=$(shell awk 'FNR==30' version.h)
SOFTREV=$(MAJOR).$(MINOR)
RPMFILE=$(RPMBASE)-$(SOFTREV)
RPMCOMPILEDIR=$(PWD)/rpmbuild
RPMSRCFILE=$(PWD)/$(RPMFILE)
RPMSPECFILE=$(RPMBASE).spec
SRCDIR?=./src

all: GOAL=all
all: $(APP_NAME)

rpm: rpmzipsrc rpmbuild

clean: GOAL=clean
clean: $(SUBDIRS)
	rm -f *.o
	rm -f doxygen.log
	rm -rf $(SRCDIR)
	rm -rf $(RPMFILE)
	rm -rf $(RPMCOMPILEDIR)
	rm -rf $(RPMSRCFILE)
	rm -f tnvme-*.tar*

clobber: GOAL=clobber
clobber: $(SUBDIRS) clean
	rm -rf Doc/HTML
	rm -rf rpm
	rm -rf Logs
	rm -f $(APP_NAME)

doc: GOAL=doc
doc: all
	doxygen doxygen.conf > doxygen.log

$(SUBDIRS):
	$(MAKE) -C $@ $(GOAL)

$(APP_NAME): $(SUBDIRS) $(SOURCES)
	$(CC) $(CFLAGS) $(INCLUDES) $(SOURCES) -o $(APP_NAME) $(LDFLAGS)

# Specify a custom source compile dir: "make src SRCDIR=../compile/dir"
# If the specified dir could cause recursive copies, then specify w/o './'
# "make src SRCDIR=src" will copy all except "src" dir.
src:
	rm -rf $(SRCDIR)
	mkdir -p $(SRCDIR)/dnvme
	(git archive HEAD) | tar xf - -C $(SRCDIR)
	git archive --remote=ssh://dcgshare.lm.intel.com/share/lm/repo/nvme/dnvme HEAD dnvme_interface.h | tar xf - -C $(SRCDIR)/dnvme
	git archive --remote=ssh://dcgshare.lm.intel.com/share/lm/repo/nvme/dnvme HEAD dnvme_ioctls.h | tar xf - -C $(SRCDIR)/dnvme

install:
	# typically one invokes this as "sudo make install"
	install -p tnvme $(DESTDIR)/usr/bin

rpmzipsrc: SRCDIR:=$(RPMFILE)
rpmzipsrc: clobber src
	rm -f $(RPMSRCFILE).tar*
	tar cvf $(RPMSRCFILE).tar $(RPMFILE)
	gzip $(RPMSRCFILE).tar

rpmbuild: rpmzipsrc
	# Build the RPM and then copy the results local
	./build.sh $(RPMCOMPILEDIR) $(RPMSPECFILE) $(RPMSRCFILE)
	rm -rf ./rpm
	mkdir ./rpm
	cp -p $(RPMCOMPILEDIR)/RPMS/x86_64/*.rpm ./rpm
	cp -p $(RPMCOMPILEDIR)/SRPMS/*.rpm ./rpm

.PHONY: all clean clobber doc $(SUBDIRS) src install rpmzipsrc rpmbuild
