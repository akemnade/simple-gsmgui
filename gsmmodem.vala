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

struct GSMCell {
  uint16 mcc;
  uint16 mcn;
  uint16 lac;
  uint32 cell; 
}

class GSMModem : Object {
  int fd;
  //FileStream fs;
  Queue<string> atcmds;
  string modemname;
  GSMCell cell;
  int registerstatus;
  char inbuf[80];
  char inbufpos;
  string [] unsoc_init = {"AT+CLIP=1","AT+CREG=2","AT+CSQ","AT+CTZU=1","AT+CREG?"};
  public signal void pin_status(bool ok);
  public signal void queue_completed(string result);
  public signal void incoming_call(string number);
  public signal void network_changed(int registerstatus, GSMCell cell);
  public signal void got_usd_msg(string answer);

  void command_result(string line) {
    stdout.printf("result: %s\n",line);
    if (atcmds.is_empty())
      return;
    atcmds.pop_head();
    if (atcmds.is_empty()) {
      queue_completed(line);
    }
  }
  void handle_queue() {
    stdout.printf("queue length: %u\n",atcmds.length);
    if (atcmds.is_empty()) {
      stdout.printf("queue empty line\n");
      return;
    }
    string cmd = atcmds.peek_head();
    stdout.printf("sending cmd: %s\n",cmd);
    Posix.write(fd,cmd,cmd.length);
    Posix.write(fd,"\r",1);
  }
  public void add_commands(string [] cmds) {
    int i;
    bool empty = atcmds.is_empty();
    for(i=0;i<cmds.length;i++) {
      atcmds.push_tail(cmds[i]);
    }
    if (empty)
      handle_queue();
  }
  public void add_command(string cmd) {
    bool empty = atcmds.is_empty();
    atcmds.push_tail(cmd);
    if (empty)
      handle_queue();
  }
  bool read_cb(IOChannel source, IOCondition condition) {
    
    ssize_t l = Posix.read(fd,inbuf+inbufpos,inbuf.length-inbufpos-1);
    int i,linecount;
    if (l<=0) {
      Posix.close(fd);
      fd = -1;
      Timeout.add(2000, modem_check_timer); 
      return false;
    }
    l+=inbufpos;
    inbuf[l]=0;
    inbufpos = 0;
    string inbufs = (string)inbuf;
    var lines = inbufs.split("\n");
    linecount = lines.length;
    for(i=0; i<(lines.length-1); i++) {
      recv_line(lines[i]);
    } 
    inbufpos=(char)lines[lines.length-1].length;
    Posix.memcpy(inbuf,lines[lines.length-1],inbufpos); 
    return true;
  }

  public void handle_clip(string cl)
  {
    var parts = cl.split(",");
    incoming_call(parts[0]);  
  }
  
  public void handle_creg(string cl)
  {
    int mode;
    uint32 lac32;
    int parts = cl.scanf("%d,%d,\"%x\",\"%x\"",out mode, out registerstatus,out lac32,out cell.cell);
    if (parts != 4) 
     parts = cl.scanf("%d,\"%x\",\"%x\"",out registerstatus,out lac32,out cell.cell);
    cell.lac = (uint16)lac32;
    stdout.printf("status: %d lac: %x cell: %x\n",registerstatus,cell.lac,cell.cell);
    if ((registerstatus == 0) || (registerstatus == 2)) {
      network_changed(registerstatus,cell);
    } else {
       add_command("AT+COPS?");
    }
  }
  
  public void handle_cops(string cl)
  {
    //allocate enough memory for sscanf
    int mode;
    int format;
   int plmnint;
    int parts = cl.scanf("%d,%d,\"%d\"",out mode,out format,out plmnint);
    string plmn = "%d".printf(plmnint);
    if ((parts > 1) && (format != 2)) {
        add_command("AT+COPS=0,2");
        add_command("AT+COPS?");
        return;
    }
    if ((parts > 2) && (format == 2)) {
        cell.mcc = (uint16)int.parse(plmn.substring(0,3));
        cell.mcn = (uint16)int.parse(plmn.substring(3,-1));
        stdout.printf("MCC: %d MCN: %d\n",
                      cell.mcc, cell.mcn);
        network_changed(registerstatus, cell);
    }
    
  }
  
  public void handle_cusd(string line)
  {
    got_usd_msg(line);
  }

  public void handle_recvinfo(string line)
  {
    var parts = line.split(": ");
    if (parts[0] == "+CPIN") {
      if (parts[1].has_prefix("READY")) {
        add_commands(unsoc_init);
        pin_status(true);
      } else {
        pin_status(false);
      }
    } else if (parts[0] == "+CLIP") {
       handle_clip(parts[1]);
    } else if (parts[0] == "+CREG") {
       handle_creg(parts[1]);
    } else if (parts[0] == "+COPS") {
       handle_cops(parts[1]);
    } else if (parts[0] == "+CUSD") {
       handle_cusd(parts[1]);
    }
  }

  public void  send_usd(string num)
  {
    add_command("AT+CUSD=1,\"%s\",15".printf(num));
  }
  public void  recv_line(string line)
  {
    /* handle stuff which is not a direct response
     * to a command
     */
    if (line[0] == '+') {
      stdout.printf("unsolic: %s\n",line);
      handle_recvinfo(line);
    }
    if (atcmds.is_empty())
      return;
    string cmd = atcmds.peek_head();
    bool is_verify = cmd.has_prefix("AT+CPIN=");
    /* some buggy firmware answers error here but it is ok */
    bool is_pcm = cmd.has_prefix("AT_OPCMENABLE");
    /* is it just an echo? */
    if (line.has_prefix(cmd)) {
      stdout.printf("echo: %s\n",line);
    } else if (line.has_prefix("+CME")) {
      command_result(line);
      atcmds.clear();
      if (is_verify)
        ask_pinstatus();
    /* command successful, handle next queue entries */
    } else if (line.has_prefix("OK") || is_pcm) {
      command_result(line);
      handle_queue();
    } else if (line.has_prefix("ERROR")) {
      command_result(line);
      atcmds.clear();
      if (is_verify)
        ask_pinstatus();
    } 
    //return true;
  }
  public void verify_pin(string pin) {
    add_command("AT+CPIN=\"%s\"".printf(pin));
    //add_command("AT+COPS".printf(pin));
    add_commands(unsoc_init);
  }
  public void send_hangup() {
    add_command("AT+CHUP");
  }
  public void ask_pinstatus() {
    add_command("AT+CPIN?");
  }
  public void dial(string number) {
    string [] cmd ={"AT_ODO=0","AT_OPCMENABLE=1",/*AT_OPCMCONFIG=...*/
                    "AT+CLVL=7", "AT_OPCMPROF=0","ATD%s;".printf(number)};
    add_commands(cmd);
  } 
  public void answer() {
    string [] cmd ={"AT_ODO=0","AT_OPCMENABLE=1",/*AT_OPCMCONFIG=...*/
		    "AT_CLVL=7","AT_OPCMPROF=0","ATA"};
    add_commands(cmd); 
  }
  public void open_modem() {
    fd = Posix.open(modemname,Posix.O_RDWR);
    if (fd < 0)
      return;
    var gioc = new IOChannel.unix_new(fd);
    gioc.add_watch(GLib.IOCondition.IN,read_cb);
    handle_queue();
  }
  public bool modem_check_timer() {
    if (fd > 0) {
      ask_pinstatus();
      return false;
    }
    open_modem();
    return true;
  }
  public GSMModem(string name) {
    modemname = name;
    atcmds = new Queue<string>();
    cell = GSMCell();
    open_modem();
    if (fd < 0) {
      Timeout.add(2000, modem_check_timer); 
    }
  }
}


