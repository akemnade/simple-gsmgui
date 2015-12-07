class GSMModem : Object {
  int fd;
  FileStream fs;
  Queue<string> atcmds;
  string modemname;
  char inbuf[80];
  char inbufpos;
  const string unsoc_init[3]={"AT+CLIP=1","AT+CREG=2","AT+CSQ"};
  public signal void pin_status(bool ok);
  public signal void queue_completed(string result);
  public signal void incoming_call(string number);
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
    }
  }

  public void  recv_line(string line)
  {
    if ((!atcmds.is_empty()) && line.has_prefix(atcmds.peek_tail())) {
      stdout.printf("echo: %s\n",line);
    } else if (line.has_prefix("+CME")) {
      command_result(line);
      atcmds.clear();
    } else if (line.has_prefix("OK")) {
      command_result(line);
      handle_queue();
    } else if (line.has_prefix("ERROR")) {
      command_result(line);
      atcmds.clear();
    } else if (line[0] == '+') {
      stdout.printf("unsolic: %s\n",line);
      handle_recvinfo(line);
    }
    //return true;
  }
  public void verify_pin(string pin) {
    add_command("AT+CPIN=\"%s\"".printf(pin));
    //add_command("AT+COPS".printf(pin));
    add_commands(unsoc_init);
  }
  public void ask_pinstatus() {
    add_command("AT+CPIN?");
  }
  public void dial(string number) {
    string cmd[4]={"AT_ODO=0","AT_OPCMENABLE=1","AT_OPCMPROF=0","ATD%s;".printf(number)};
    add_commands(cmd);
  } 
  public void answer() {
    string cmd[4]={"AT_ODO=0","AT_OPCMENABLE=1","AT_OPCMPROF=0","ATA"};
    add_commands(cmd); 
  }
  public void open_modem() {
    fd = Posix.open(modemname,Posix.O_RDWR);
    if (fd < 0)
      return;
    fs = FileStream.fdopen(fd,"r+");
    var gioc = new IOChannel.unix_new(fd);
    gioc.add_watch(GLib.IOCondition.IN,read_cb);
  }
  public GSMModem(string name) {
    modemname = name;
    atcmds = new Queue<string>();
   open_modem();
  }
}


