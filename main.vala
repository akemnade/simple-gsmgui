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


bool nwselect_pending = false;
GSMModem modem;
PhoneDlg phonedlg;
bool saved_pin_status = false;
bool first_pincheck = true;
string cellfilename = null;
void pin_status(bool ok) {
  saved_pin_status = ok;
  cancel_usd();
  if (!ok) {
    phonedlg.show_all();
    phonedlg.update_dialbutton("OK","OK");
    phonedlg.statusline.label = "Enter PIN";
    phonedlg.phoneline.text = "";
  } else {
    phonedlg.update_dialbutton("Answer","Dial");
    if (first_pincheck)
      phonedlg.show_all();
    first_pincheck = false;
    phonedlg.statusline.label = "PIN ok";
    stdout.printf("ok\n");
    if (nwselect_pending) {
      nwselect_pending = false;
      open_network_chooser();
    }
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

void call_state_changed(GSMModem.CallState state)
{
  phonedlg.phoneline.text = "";
  stdout.printf("call state changed (gui)\n");
  if (state == GSMModem.CallState.INACTIVE) {
    phonedlg.statusline.label = "no call active";
    call_hangupscript();
  }
}

void dialbuttoncb()
{
  string number = phonedlg.phoneline.text;
  phonedlg.update_dialbutton("Answer", "Dial");
  phonedlg.phoneline.text = "";
  if (!saved_pin_status) {
    modem.verify_pin(number);
    modem.ask_pinstatus();
    phonedlg.hide();
  } else if (number.length>0) {
    if ((number[0]=='*') || (phonedlg.in_usd && (number.length == 1))) {
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

void call_hangupscript()
{
  try {
	  
	  Pid pid;
	  Process.spawn_async(null,{"gsmgui-hungup.sh"},null,SpawnFlags.SEARCH_PATH,null,out pid);
	  Process.close_pid(pid);
  } catch(SpawnError err) {
  }
}

void hangupbuttoncb()
{
  if (saved_pin_status)
      phonedlg.statusline.label="";

  cancel_usd();
  modem.send_hangup();
  call_hangupscript();
}

NetworkChooser nchooser = null;
void mysigusr1()
{
  phonedlg.show_all();
}

void network_chosen()
{
  stdout.printf("network choosen");
  nchooser = null;
}


void mysigusr2()
{
  if (!saved_pin_status) {
    phonedlg.show_all();
    nwselect_pending = true;
  } else {
    open_network_chooser();
  }
}

void open_network_chooser()
{
  if (nchooser != null)
    return;
  nchooser = new NetworkChooser(modem);
  nchooser.done.connect(network_chosen);
  nchooser.start();
}

bool hidedlg(Gdk.Event event)
{
  phonedlg.hide();
  phonedlg.phoneline.text = "";
  return true;
}

void display_usd_msg(bool cont, string answer)
{
  phonedlg.in_usd = cont;
  phonedlg.statusline.label = "Answer: \n" + answer;
}


void cancel_usd()
{
  phonedlg.in_usd = false;
}

void process_digit(string num) {
  if (modem.call_state == GSMModem.CallState.ACTIVE) {
    modem.send_dtmf(num);
  }
}

void nw_changed(int registerstatus, GSMCell cell)
{
  string status = "unknown";
  cancel_usd();
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
    case -1:
    phonedlg.title="Phone: modem off";
    phonedlg.statusline.label="modem off";
    return;
  }
  phonedlg.title="Phone: %s (%s) %x/%x".printf(cell.operator,status,cell.lac,cell.cell);
  if (cellfilename != null) {
    FileStream fs = FileStream.open(cellfilename,"w");
    if (fs != null)
      fs.printf("%u %u %x %x",cell.mcc,cell.mcn,cell.lac,cell.cell);
  }

}

int main(string [] args) {
  Gtk.init(ref args);
  if ((args.length > 1) && (args[1] == "--nwselect")) {
    nwselect_pending = true;
  }
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
  phonedlg.digit_pressed.connect(process_digit);
  modem = new GSMModem("/dev/ttyHS_Application");  
  modem.pin_status.connect(pin_status);   
  modem.incoming_call.connect(incoming_call);
  modem.network_changed.connect(nw_changed);
  modem.got_usd_msg.connect(display_usd_msg);
  modem.call_state_changed.connect(call_state_changed);
  phonedlg.dialbutton.clicked.connect(dialbuttoncb);
  phonedlg.hangupbutton.clicked.connect(hangupbuttoncb);
  Posix.signal(Posix.SIGUSR1,mysigusr1);
  Posix.signal(Posix.SIGUSR2,mysigusr2);
  Gtk.main();
  return 0;
}
