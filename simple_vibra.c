/**********************************************************************
 simple-gsmgui - Copyright (C) 2015 - Andreas Kemnade
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3, or (at your option)
 any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied
 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
***********************************************************************/

#include <linux/input.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) 
{
  int i,id,j;
  int starttime;
  int fd;
  struct input_event *ev;
  if (argc < 3) {
    printf("Usage: %s vibrafile ontime offtime ..",argv[0]);
  }
  fd=open(argv[1],O_RDWR);
  if (fd<0) {
    fprintf(stderr,"cannot open %s\n",argv[1]);
    return 1;
  }
  argc-=2;
  argv++;
  argv++; 
  ev=malloc(sizeof(struct input_event)*argc);
  j=0;
  starttime=0;
  for(i = 0; i < argc; i++) {
    int t=atoi(argv[i]);
    if ((i&1)==0) {
      struct ff_effect ff;
      ff.type=FF_RUMBLE;
      ff.id=-1;
      ff.direction=0;
      ff.trigger.button=0;
      ff.trigger.interval=0;
      ff.u.rumble.strong_magnitude=0xffff;
      ff.u.rumble.weak_magnitude=0; 
      ff.replay.length=t;
      ff.replay.delay=starttime;
      if (0<=ioctl(fd,EVIOCSFF,&ff)) {
        ev[j].time.tv_sec=0;
        ev[j].time.tv_usec=0;
        ev[j].type=0x15;
        ev[j].code=ff.id;
        ev[j].value=1;
        j++;
      }
    }
    starttime+=t;
  } 
  write(fd,ev,j*sizeof(struct input_event));
  usleep(starttime*1000);
  close(fd);
}
