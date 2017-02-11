#!/bin/bash
killall simple-vibra
K="$(uname -r)" 
K2=""
VOICEFILE=""
VOICEFILE_BASE="/usr/local/share/gsmgui/voice"
# accect different alsa state files for different kernels
# search for e.g voice-4.10.0 voice-4.10 voice-4
while [ "$K" != "$K2" ] 
do 
  K2="$K" 
  #echo $K 
  VOICEFILE="$VOICEFILE_BASE-$K"
  if [ -f "$VOICEFILE" ] ; then
    alsactl -f "$VOICEFILE" restore && break 
  fi 
  VOICEFILE=""
  K=${K%.*}
done
# voice with no kernel prefix
if [ "$VOICEFILE" = "" ] ; then
  alsactl -f "$VOICEFILE_BASE" restore
fi
amixer set 'Voice Route out' on 
