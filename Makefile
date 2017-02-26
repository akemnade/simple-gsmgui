PREFIX ?= /usr/local

all: simple-gsmgui gsmgui-ring.sh gsmgui-start-audio.sh gsmgui-hungup.sh start-gsmgui.sh simple_vibra
simple-gsmgui: gsmgui.vala gsmmodem.vala
	valac $^ -o simple-gsmgui --pkg gtk+-2.0 --pkg posix

simple_vibra: simple_vibra.c

%.sh: %.in
	sed "s-PREFIX-$(PREFIX)-g" <$^ >$@

install: 
	install -m 755 -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 -t $(DESTDIR)$(PREFIX)/bin simple-gsmgui gsmgui-ring.sh gsmgui-start-audio.sh gsmgui-hungup.sh start-gsmgui.sh simple_vibra
	install -m 755 -d $(DESTDIR)$(PREFIX)/share/gsmgui
	install -m 644 -t $(DESTDIR)$(PREFIX)/share/gsmgui voice-4 voice

clean:
	rm -f simple-gsmgui simple_vibra gsmgui-start-audio.sh

.PHONY: install clean all
