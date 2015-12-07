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
    statusline = new Gtk.Label("enter PIN");
    vbox.pack_start(statusline, false,false,0);
    var hbox = new Gtk.HBox(false,0);
    vbox.pack_start(hbox,false,false,0);
    phoneline = new Gtk.Entry();
    hbox.pack_start(phoneline, true,true,0);
    backbutton = new Gtk.Button.with_label("<-");
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

int main(string [] args) {
  Gtk.init(ref args);
  var phonedlg = new PhoneDlg();
  phonedlg.show_all();  
  Gtk.main();
  return 0;
}
