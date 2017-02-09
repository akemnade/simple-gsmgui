#!/bin/bash
killall simple-vibra
alsactl -f /usr/local/share/gsmgui/voice restore
amixer set 'Voice Route out' on || (
sleep 1
i2cset -f -y 0 0x49 0x04 0x05
i2cset -f -y 0 0x49 0x21 0x31
i2cset -f -y 0 0x49 0x17 0x14
i2cset -f -y 0 0x49 0x44 0x03
)
