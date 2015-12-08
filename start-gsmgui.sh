#!/bin/bash
if pgrep gsmgui ; then
  killall -USR1 gsmgui
else
  gsmgui
fi

