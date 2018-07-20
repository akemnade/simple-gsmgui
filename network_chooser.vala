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

class NetworkChooser : Gtk.Dialog {
  Gtk.Button automode;
  Gtk.Button searchbutton;
  Gtk.Label searchlabel;
  GSMModem modem;
  public signal void done();
  
  void automode_clicked() {
    modem.set_auto_network();
    destroy();
    done();
  }

  void search_clicked() {
    modem.search_networks();
    searchbutton.hide();
    searchlabel.show();
  }

  void net_button_clicked(Gtk.Button b) {
    modem.set_network(b.get_data("net"));
    destroy();
    done(); 
  }	

  void nets_found(GSMNet [] nets) {
    searchlabel.hide();

    for(int i = 0; i < nets.length; i++) {
      var but = new Gtk.Button.with_label(nets[i].name);
      ((Gtk.Box)get_content_area()).pack_start(but, false, true, 0);
      but.set_data("net", nets[i].number);
      but.clicked.connect(net_button_clicked);
      but.show();
    }
  }
  
  private bool close_chooser(Gdk.Event e) {
    destroy();
    done();
    return true;
  }

  public NetworkChooser(GSMModem modem) {
    this.modem = modem;
    set_title("choose a network");
    modem.got_network_list.connect(nets_found);
    Gtk.Box vb = (Gtk.Box)get_content_area();
    automode = new Gtk.Button.with_label("auto mode");
    vb.pack_start(automode, false, true, 0);
    automode.clicked.connect(automode_clicked);
    searchlabel = new Gtk.Label("searching networks");
    vb.pack_start(searchlabel, false, true, 0);
    searchbutton = new Gtk.Button.with_label("search networks");
    searchbutton.clicked.connect(search_clicked);
    vb.pack_start(searchbutton, false, true, 0);
    delete_event.connect(close_chooser); 
  }

  public void start() {
    automode.show();
    searchbutton.show();
    get_content_area().show();
    show();
  }
}

