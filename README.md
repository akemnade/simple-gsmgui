# simple-gsmgui
a simple x11 phoneui for the openphoenux

This is a simple phoneui for the openphoenux. It does not have much dependancies, only gtk2. So it can fit into your environment if gtk2 is available. 
The reason I wrote it is: I was tired of all the hard dependancies of
other alternatives which might be incomplete or be broken from time to time. 
The letux-dial script is a little too less functionality.

Maybe in future it can try to talk with whatever phone-related stuff is on dbus first, then fall back to direct modem communication.

Features:
- asks for pin if needed
- offers a keypad to dial
- stays in background to answer calls
- writes current cell information into ~/gsminfo/cell
- waits for modem to (re)-appear in /dev

Usage:
start-gsmgui.sh
starts the program if it is not running, else
it is brought to foreground

Scripts:
gsmgui-start-audio.sh
called on dialing or answering the phone,
sets alsa configuration for voice routing

gsmgui-ring.sh
called on incoming call
can play ring tones or enable the vibrator
