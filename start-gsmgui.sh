#!/bin/bash
if pgrep -x simple-gsmgui ; then
  killall -USR1 simple-gsmgui
else
  simple-gsmgui
fi

