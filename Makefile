gsmgui: gsmgui.vala gsmmodem.vala
	valac $^ -o gsmgui --pkg gtk+-2.0 --pkg posix

install: gsmgui
	install -m 755 -t /usr/local/bin gsmgui gsmgui-ring.sh gsmgui-start-audio.sh gsmgui-hungup.sh start-gsmgui.sh
	install -m 755 -d /usr/local/share/gsmgui
	install -m 644 -t /usr/local/share/gsmgui voice
