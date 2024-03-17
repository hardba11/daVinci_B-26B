var sin = func(a) { math.sin(a * math.pi / 180.0) }
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var blower0 = props.globals.getNode("controls/engines/engine[0]/boost");
var blower1 = props.globals.getNode("controls/engines/engine[1]/boost");

init = func {
  setprop ("/autopilot/locks/heading" , "none" );
  setprop ("/autopilot/locks/altitude" , "none" );

  if (getprop("/controls/engines/engine[0]/on-startup-running") == 1) {
    setprop("/consumables/fuel/tank[1]/selected",1);
    setprop("/controls/engines/engine[0]/magnetos",3);
    setprop("/controls/engines/engine[0]/coolflap-auto",1);
#    setprop("/controls/engines/engine[0]/radlever",1);
    setprop("/engines/engine[0]/oil-visc",1);
    setprop("/engines/engine[0]/rpm",800);
    setprop("/engines/engine[0]/engine-running",1);
  }
  if (getprop("/controls/engines/engine[1]/on-startup-running") == 1) {
    setprop("/consumables/fuel/tank[3]/selected",1);
    setprop("/controls/engines/engine[1]/magnetos",3);
    setprop("/controls/engines/engine[1]/coolflap-auto",1);
#    setprop("/controls/engines/engine[1]/radlever",1);
    setprop("/engines/engine[1]/oil-visc",1);
    setprop("/engines/engine[1]/rpm",800);
    setprop("/engines/engine[1]/engine-running",1);
  }
 main_loop();
}

setlistener("/controls/fuel/switch-position-port", func (n) {
  position = n.getValue();
  setprop("/consumables/fuel/tank[0]/selected", 0);
  setprop("/consumables/fuel/tank[1]/selected", 0);
  if(position >= 0.0) {
    setprop("/consumables/fuel/tank[" ~ position ~ "]/selected", 1);
    setprop("/engines/engine[0]/out-of-fuel", 0);
  }
}, 1);

setlistener("/controls/fuel/switch-position-starb", func (n) {
  position = n.getValue();
  setprop("/consumables/fuel/tank[2]/selected",0);
  setprop("/consumables/fuel/tank[3]/selected",0);
  if(position >= 2.0) {
    setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);
    setprop("/engines/engine[0]/out-of-fuel",0);
  }
}, 1);

main_loop = func {
  settimer(main_loop, 0.01);
}

var shift_blower0_up = func {
  if (blower0.getValue() <= 0.46) {
    interpolate("controls/engines/engine[0]/boost", 1, 30);
  }
}
var shift_blower0_dn = func {
  if (blower0.getValue() >= 1.0) {
    interpolate("controls/engines/engine[0]/boost", 0.46, 30);
  }
}
var shift_blower1_up = func {
  if (blower0.getValue() <= 0.46) {
    interpolate("controls/engines/engine[1]/boost", 1, 30);
  }
}
var shift_blower1_dn = func {
  if (blower0.getValue() >= 1.0) {
    interpolate("controls/engines/engine[1]/boost", 0.46, 30);
  }
}


# setlistener("/sim/signals/fdm-initialized",init);
















