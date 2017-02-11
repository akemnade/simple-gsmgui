simple-gsmgui: gsmgui.vala gsmmodem.vala
	valac $^ -o simple-gsmgui --pkg gtk+-2.0 --pkg posix

install: simple-gsmgui
	install -m 755 -t /usr/local/bin simple-gsmgui gsmgui-ring.sh gsmgui-start-audio.sh gsmgui-hungup.sh start-gsmgui.sh
	install -m 755 -d /usr/local/share/gsmgui
	install -m 644 -t /usr/local/share/gsmgui voice-4 voice
