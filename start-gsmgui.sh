#!/bin/bash
if pgrep -x gsmgui ; then
  killall -USR1 gsmgui
else
  gsmgui
fi

