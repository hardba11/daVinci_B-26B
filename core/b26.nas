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

fire_MG = func {
  if (getprop("/controls/armament/master-arm") == 1) {
    if (getprop("sim/current-view/view-number") == 8) {
      setprop("/controls/armament/trigger2", 1);
    } else {
      setprop("/controls/armament/trigger", 1);
    }
  }
}

stop_MG = func {
  setprop("/controls/armament/trigger", 0); 
  setprop("/controls/armament/trigger2", 0);
}

drop_torp = func {
  if (getprop("/controls/armament/master-arm") == 1)  {
    rcount=getprop("/sim/weight[0]/weight-lb");
    if(rcount > 49){
      setprop("/controls/armament/station/release-all", 1);
      setprop("/sim/weight[0]/selected", "none");
    }
  }
}

fire_rp = func {
  if (getprop("/controls/armament/master-arm") == 1) {
    rcount=getprop("/sim/weight[1]/weight-lb");
    if(rcount > 20) {
      if(rcount == 260) {
        setprop("/controls/armament/pair1", 1)
      } else {
        if(rcount == 200) {
          setprop("/controls/armament/pair2", 1)
        } else {
          if(rcount == 140) {
            setprop("/controls/armament/pair3", 1)
          } else {
            if(rcount == 80) {
              setprop("/controls/armament/pair4", 1)
            }
          }
        }
      }
      setprop("sim/weight[1]/weight-lb", rcount - 60.0);
      setprop("sim/weight[2]/weight-lb", rcount - 60.0);
    }
  }
}


toggle_fdoor = func {
  canopy = aircraft.door.new ("/controls/doors/fdoor/",3);
  if (getprop("//controls/doors/fdoor/position-norm") > 0) {
    canopy.close();
  } else {
    canopy.open();
  }
}

toggle_rdoor = func {
  canopy = aircraft.door.new ("/controls/doors/rdoor/",3);
  if(getprop("//controls/doors/rdoor/position-norm") > 0) {
    canopy.close();
  } else {
    canopy.open();
  }
}

toggle_cdoor = func {
  canopy = aircraft.door.new ("/controls/doors/cdoor/",3);
  if(getprop("//controls/doors/cdoor/position-norm") > 0) {
    canopy.close();
  } else {
    canopy.open();
  }
}

toggle_gunsight = func {
  canopy = aircraft.door.new ("/controls/switches/gun-sight-stow/",3);
  if (getprop("//controls/switches/gun-sight-stow/position-norm") > 0) {
    canopy.close();
  } else {
    canopy.open();
  }
  if(getprop("controls/switches/gun-sight-stow") > 0) {
    interpolate("controls/switches/gun-sight-stow", 0, 2);
  } else {
    interpolate("controls/switches/gun-sight-stow", 1, 2);
  }
}

fuel_jettison = func(side) {
  remaining_inner = getprop("consumables/fuel/tank["~side~"]/level-gal_us");
  remaining_outer = getprop("consumables/fuel/tank["~(side+1)~"]/level-gal_us");
  interpolate("consumables/fuel/tank["~side~"]/level-gal_us", (remaining_inner-20),5);
  interpolate("consumables/fuel/tank["~(side+1)~"]/level-gal_us", (remaining_outer-15),5);
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

var flash_trigger = props.globals.getNode("controls/armament/trigger", 0);
aircraft.light.new("sim/model/beaufighter/lighting/flash-lu", [0.05, 0.052], flash_trigger);
aircraft.light.new("sim/model/beaufighter/lighting/flash-ld", [0.052, 0.05], flash_trigger);
aircraft.light.new("sim/model/beaufighter/lighting/flash-ru", [0.051, 0.051], flash_trigger);
aircraft.light.new("sim/model/beaufighter/lighting/flash-rd", [0.0505, 0.0505], flash_trigger);

var bombbay = aircraft.door.new ("/controls/armament/bombbay/",5);

# setlistener("/sim/signals/fdm-initialized",init);
















