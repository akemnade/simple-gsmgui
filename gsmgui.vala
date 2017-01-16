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

class PhoneDlg : Gtk.Dialog {
  public Gtk.Label statusline;
  public Gtk.Entry phoneline;
  public Gtk.Table numberfield;
  public Gtk.Button dialbutton;
  public Gtk.Button hangupbutton;
  public Gtk.Button backbutton;
  void dellast() {
    int p = phoneline.cursor_position;
    if (phoneline.text.length > 0)
      phoneline.text = phoneline.text.substring(0,phoneline.text.length-1);
  }
  void numbfunc(Gtk.Button b) { int pos = phoneline.cursor_position;
         string addstr= b.get_label();
         phoneline.text+=addstr;
  } 
  public PhoneDlg() {
    set_title("Phone");
    dialbutton = new Gtk.Button.with_label("Dial"); 
    hangupbutton = new Gtk.Button.with_label("Hangup");
    action_area.pack_start(dialbutton, true,true,0);
    action_area.pack_end(hangupbutton, true,true,0);
    statusline = new Gtk.Label("status");
    vbox.pack_start(statusline, false,false,0);
    var hbox = new Gtk.HBox(false,0);
    vbox.pack_start(hbox,false,false,0);
    phoneline = new Gtk.Entry();
    hbox.pack_start(phoneline, true,true,0);
    backbutton = new Gtk.Button.with_label("<<---");
    hbox.pack_end(backbutton,false,false,0);
    backbutton.clicked.connect(dellast); 
    numberfield = new Gtk.Table(4,3,true);
    vbox.pack_start(numberfield,true,true,0);
    string nums[12]={"1","2","3","4","5","6","7","8","9","*","0","#"};
    int i;
    for(i=0;i<nums.length;i++) {
      var but = new Gtk.Button.with_label(nums[i]);
      numberfield.attach(but, i%3, i%3+1, i/3, i/3+1,
	Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
        Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,5,5);
      but.clicked.connect(numbfunc);
    }
  }
}

GSMModem modem;
PhoneDlg phonedlg;
bool saved_pin_status = false;
bool first_pincheck = true;
string cellfilename = null;
void pin_status(bool ok) {
  saved_pin_status = ok;
  if (!ok) {
  phonedlg.show_all();
  phonedlg.statusline.label = "Enter PIN";
  } else {
    if (first_pincheck)
      phonedlg.show_all();
    first_pincheck = false;
    phonedlg.statusline.label = "PIN ok";
    stdout.printf("ok\n");
  }
}

void incoming_call(string number)
{
  stdout.printf("call from: %s",number);
  try {
	  Pid pid;
	  Process.spawn_async(null,{"gsmgui-ring.sh"},null,SpawnFlags.SEARCH_PATH,null,out pid);
	  Process.close_pid(pid);
  } catch (SpawnError err) {
  }
  phonedlg.statusline.label="call from: %s".printf(number);
  phonedlg.show_all();
}

void dialbuttoncb()
{
  string number = phonedlg.phoneline.text;
  phonedlg.phoneline.text = "";
  if (!saved_pin_status) {
    modem.verify_pin(number);
    modem.ask_pinstatus();
    phonedlg.hide();
  } else if (number.length>0) {
    if (number[0]=='*') {
      phonedlg.statusline.label="waiting for answer to: %s\n".printf(number);
      modem.send_usd(number);
      return;
    }
	try {
		Pid pid;
		Process.spawn_async(null,{"gsmgui-start-audio.sh"},null,SpawnFlags.SEARCH_PATH,null,out pid);
		Process.close_pid(pid);
	} catch(SpawnError err) {
	}
    modem.dial(number);
    phonedlg.statusline.label="call to: %s".printf(number);
  } else {
	  try {
		  
		  Pid pid;
		  Process.spawn_async(null,{"gsmgui-start-audio.sh"},null,SpawnFlags.SEARCH_PATH,null,out pid);
		  Process.close_pid(pid);
	  } catch(SpawnError err) {
	  }
	  modem.answer();
  }
}

void hangupbuttoncb()
{
  modem.send_hangup();
}

void mysigusr1()
{
  phonedlg.show_all();
}

bool hidedlg(Gdk.Event event)
{
  phonedlg.hide();
  phonedlg.phoneline.text = "";
  return true;
}

void nw_changed(int registerstatus, GSMCell cell)
{
  string status = "unknown";
  switch (registerstatus) {
    case 0:
    case 2:
    phonedlg.title="Phone: not registered";
    if (cellfilename != null)
	Posix.unlink(cellfilename); 
    return;
    case 1:
    status = "home";
    break;
    case 5:
    status = "roaming";
    break;
  }
  phonedlg.title="Phone: %s %x/%x".printf(status,cell.lac,cell.cell);
  if (cellfilename != null) {
    FileStream fs = FileStream.open(cellfilename,"w");
    if (fs != null)
      fs.printf("%u %u %x %x",cell.mcc,cell.mcn,cell.lac,cell.cell);
  }

}

int main(string [] args) {
  Gtk.init(ref args);
  string celltmp = Environment.get_tmp_dir()+"/gsminfo.XXXXXX";
  string celltmpres = DirUtils.mkdtemp(celltmp);
  if (celltmpres != null) {
    string gsminfo = Environment.get_home_dir() + "/gsminfo"; 
    Posix.unlink(gsminfo);
    Posix.symlink(celltmp, gsminfo);
    cellfilename = celltmpres + "/cell";
  }
  phonedlg = new PhoneDlg();
  phonedlg.delete_event.connect(hidedlg);
  modem = new GSMModem("/dev/ttyHS_Application");  
  modem.pin_status.connect(pin_status);   
  modem.incoming_call.connect(incoming_call);
  modem.network_changed.connect(nw_changed);
  phonedlg.dialbutton.clicked.connect(dialbuttoncb);
  phonedlg.hangupbutton.clicked.connect(hangupbuttoncb);
  modem.ask_pinstatus();
  Posix.signal(Posix.SIGUSR1,mysigusr1);
  Gtk.main();
  return 0;
}
