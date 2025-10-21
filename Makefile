CAT?=cat
SED?=sed
CC?=clang
YACC?=yacc
BIN=duoas
PREFIX?=/usr/local
MANDIR?=$(DESTDIR)$(PREFIX)/man
SYSCONFDIR?=$(DESTDIR)$(PREFIX)/etc
DUOAS_CONF=$(SYSCONFDIR)/duoas.conf
OBJECTS=duoas.o env.o compat/execvpe.o compat/reallocarray.o y.tab.o 
OPT?=-O2
# Can set GLOBAL_PATH here to set PATH for target user.
# TARGETPATH=-DGLOBAL_PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\"
CFLAGS+=-Wall $(OPT) -DUSE_PAM -DDUOAS_CONF=\"$(DUOAS_CONF)\" $(TARGETPATH)
CPPFLAGS+=-include compat/compat.h
LDFLAGS+=-lpam
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    LDFLAGS+=-lpam_misc
    CPPFLAGS+=-Icompat
    CFLAGS+=-D_GNU_SOURCE
    COMPAT+=closefrom.o errc.o getprogname.o setprogname.o strlcat.o strlcpy.o strtonum.o verrc.o
    OBJECTS+=$(COMPAT:%.o=compat/%.o)
endif
ifeq ($(UNAME_S),FreeBSD)
    CFLAGS+=-DHAVE_LOGIN_CAP_H
    LDFLAGS+=-lutil
endif
ifeq ($(UNAME_S),MidnightBSD)
    CFLAGS+=-DHAVE_LOGIN_CAP_H
    LDFLAGS+=-lutil
endif
ifeq ($(UNAME_S),NetBSD)
    CFLAGS+=-DHAVE_LOGIN_CAP_H -D_OPENBSD_SOURCE
    OBJECTS=duoas.o env.o y.tab.o
    LDFLAGS+=-lutil
endif
ifeq ($(UNAME_S),SunOS)
    SAFE_PATH?=/bin:/sbin:/usr/bin:/usr/sbin:$(PREFIX)/bin:$(PREFIX)/sbin
    GLOBAL_PATH?=/bin:/sbin:/usr/bin:/usr/sbin:$(PREFIX)/bin:$(PREFIX)/sbin
    CPPFLAGS+=-Icompat
    CFLAGS+=-DSOLARIS_PAM -DSAFE_PATH=\"$(SAFE_PATH)\" -DGLOBAL_PATH=\"$(GLOBAL_PATH)\"
    COMPAT=errc.o pm_pam_conv.o setresuid.o verrc.o
    OBJECTS+=$(COMPAT:%.o=compat/%.o)
endif
ifeq ($(UNAME_S),Darwin)
    CPPFLAGS+=-Icompat
    COMPAT+=bsd-closefrom.o
    OBJECTS+=$(COMPAT:%.o=compat/%.o)
    # On MacOS the default man page path is /usr/local/share/man
    MANDIR=$(DESTDIR)$(PREFIX)/share/man
endif

FINALS=duoas.1.final duoas.conf.5.final viduoas.final viduoas.8.final 

all: $(BIN) $(FINALS)

$(BIN): $(OBJECTS)
	$(CC) -o $(BIN) $(OBJECTS) $(LDFLAGS)

env.o: duoas.h env.c

execvpe.o: duoas.h execvpe.c

duoas.o: duoas.h duoas.c parse.y

reallocarray.o: duoas.h reallocarray.c

y.tab.o: parse.y
	$(YACC) parse.y
	$(CC) $(CPPFLAGS) $(CFLAGS) -c y.tab.c

install: $(BIN) $(FINALS)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp $(BIN) $(DESTDIR)$(PREFIX)/bin/
	chmod 4755 $(DESTDIR)$(PREFIX)/bin/$(BIN)
	cp viduoas.final $(DESTDIR)$(PREFIX)/bin/viduoas
	chmod 755 $(DESTDIR)$(PREFIX)/bin/viduoas
	cp duoasedit $(DESTDIR)$(PREFIX)/bin/duoasedit
	chmod 755 $(DESTDIR)$(PREFIX)/bin/duoasedit
	mkdir -p $(MANDIR)/man1
	cp duoas.1.final $(MANDIR)/man1/duoas.1
	mkdir -p $(MANDIR)/man5
	cp duoas.conf.5.final $(MANDIR)/man5/duoas.conf.5
	mkdir -p $(MANDIR)/man8
	cp viduoas.8.final $(MANDIR)/man8/viduoas.8
	cp duoasedit.8 $(MANDIR)/man8/duoasedit.8

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/duoas
	rm -f $(DESTDIR)$(PREFIX)/bin/viduoas
	rm -f $(DESTDIR)$(PREFIX)/bin/duoasedit
	rm -f $(MANDIR)/man1/duoas.1
	rm -f $(MANDIR)/man5/duoas.conf.5
	rm -f $(MANDIR)/man8/viduoas.8
	rm -f $(MANDIR)/man8/duoasedit.8

clean:
	rm -f $(BIN) $(OBJECTS) y.tab.c
	rm -f *.final parse.o

# Doing it this way allows to change the original files
# only partially instead of renaming them.
duoas.1.final: duoas.1
duoas.conf.5.final: duoas.conf.5
viduoas.final: viduoas
viduoas.8.final: viduoas.8
$(FINALS):
	$(CAT) $^ | $(SED) 's,@DUOAS_CONF@,$(DUOAS_CONF),g' > $@
