# Cross-compile hello for the UDOO Quad (ARMv7, hard-float)

CROSS_COMPILE ?= arm-linux-gnueabihf-
CC            := $(CROSS_COMPILE)gcc
CFLAGS        ?= -O2 -Wall -Wextra
LDFLAGS       ?= -static
NFS_ROOT      ?= /srv/nfs/udoo

TARGET := hello

all: $(TARGET)

$(TARGET): hello.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

install: $(TARGET)
	sudo install -m 755 $(TARGET) $(NFS_ROOT)/usr/bin/

clean:
	rm -f $(TARGET)

.PHONY: all install clean
