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
  public Gtk.ToolButton pastebutton;
  string okempty;
  string oknonempty;
  public bool in_usd;
  public signal void digit_pressed(string number); 
  public void update_dialbutton(string empty, string nonempty) {
    okempty = empty;
    oknonempty = nonempty;
    linechanged();
  }
  void dellast() {
    // int p = phoneline.cursor_position;
    if (phoneline.text.length > 0)
      phoneline.text = phoneline.text.substring(0,phoneline.text.length-1);
  }
  void got_clipboard_text(Gtk.Clipboard clip, string? text) {
     if (text != null) {
       var filtered = new StringBuilder();
       bool first_seen = false;
       int i;
       for(i = 0; i < text.length ; i++) {
         if ((!first_seen) && (text[i] == '+')) {
           first_seen = true;
           filtered.append_c('+');
         } else if (text[i].isdigit()) {
           first_seen = true;
           filtered.append_c(text[i]);
         }
       }

       phoneline.text = filtered.str;
     }
  }

  void paste_number() {
    var clip = Gtk.Clipboard.get_for_display(get_display(),Gdk.SELECTION_PRIMARY);
    clip.request_text(got_clipboard_text); 
    //phoneline.paste_clipboard();
  }
  void numbfunc(Gtk.Button b) {
	  //int pos = phoneline.cursor_position;
         string addstr = b.get_data("num");
         digit_pressed(addstr);
         phoneline.text+=addstr;
  } 
  void linechanged() {
    if (phoneline.text.length != 0) {
      dialbutton.set_label(oknonempty);
    } else {
      dialbutton.set_label(okempty);
    }
  }
  public PhoneDlg() {
    Gtk.Box vb = (Gtk.Box)get_content_area(); 
    Gtk.Box hb = (Gtk.Box)get_action_area();
    set_title("Phone: modem off");
    okempty = "Answer";
    oknonempty = "Dial";
    in_usd = false;
    dialbutton = new Gtk.Button.with_label("Answer"); 
    hangupbutton = new Gtk.Button.with_label("Hangup");
    hb.pack_start(dialbutton, true,true,0);
    hb.pack_end(hangupbutton, true,true,0);
    statusline = new Gtk.Label("status");
    vb.pack_start(statusline, false,false,0);
    var hbox = new Gtk.HBox(false,0);
    vb.pack_start(hbox,false,false,0);
    phoneline = new Gtk.Entry();
    phoneline.changed.connect(linechanged);
    hbox.pack_start(phoneline, true,true,0);
    backbutton = new Gtk.Button.with_label("<<---");
    hbox.pack_end(backbutton,false,false,0);
    backbutton.clicked.connect(dellast); 
    //pastebutton = new Gtk.Button.with_label("P");
    pastebutton = new Gtk.ToolButton.from_stock(Gtk.Stock.PASTE);
    pastebutton.clicked.connect(paste_number);
    hbox.pack_end(pastebutton,false,false,0);
    numberfield = new Gtk.Table(4,3,true);
    vb.pack_start(numberfield,true,true,0);
    string nums[12]={"1","2","3","4","5","6","7","8","9","*","0","#"};
    int i;
    for(i=0;i<nums.length;i++) {
      var but = new Gtk.Button();
      var label = new Gtk.Label(null);
      label.set_markup("<span font_size='xx-large'>%s</span>".printf(nums[i]));
      but.add(label);
      but.set_data("num", nums[i]);
      numberfield.attach(but, i%3, i%3+1, i/3, i/3+1,
	Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
        Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,10,10);
      but.clicked.connect(numbfunc);
    }
  }
}

