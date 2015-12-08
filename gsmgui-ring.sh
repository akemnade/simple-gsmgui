#!/bin/sh
pgrep simple_vibra || simple_vibra /dev/input/rumble 300 10
