GSMModem modem;
void pin_status(bool ok) {
  if (!ok) {
  stdout.printf("PIN: ");
  string pin = stdin.read_line();
  modem.verify_pin(pin);
  } else {
    stdout.printf("ok\n");
  }
}

void incoming_call(string number)
{
  stdout.printf("call from: %s",number);
   
}

public void main(string [] args)
{
  var mainloop = new MainLoop();
  modem = new GSMModem("/dev/ttyHS_Application");  
  modem.ask_pinstatus();
  modem.pin_status.connect(pin_status);   
  modem.incoming_call.connect(incoming_call);   

  mainloop.run();
}
