#!/bin/bash
if pgrep -x simple-gsmgui ; then
  killall -USR2 simple-gsmgui
else
  simple-gsmgui --nwselect
fi

