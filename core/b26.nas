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


var event_click_hold_autopilot = func()
{
    # set AP altitude as curent altitude
    var curr_alt = getprop("/instrumentation/altimeter/indicated-altitude-ft") or 5000;
    setprop("/autopilot/settings/target-altitude-ft", curr_alt);

    # set AP speed as current speed
    var curr_speed = getprop("/instrumentation/airspeed-indicator/true-speed-kt") or 300;
    setprop("/autopilot/settings/target-speed-kt", curr_speed);

    # set AP heading as curent heading
    var curr_heading = getprop("/orientation/heading-magnetic-deg") or 0;
    setprop("/autopilot/settings/heading-bug-deg", curr_heading);

    # arm AP for altitude, speed and heading
    setprop("/autopilot/internal/target-roll-deg",          0);
    setprop("/autopilot/internal/target-climb-rate-fps",    0);
    setprop("/autopilot/locks/altitude",                    'altitude-hold');
    setprop("/autopilot/locks/heading",                     'dg-heading-hold');
    event_click_lock_speed(1);
}

var event_click_disengage_autopilot = func()
{
    # disengage AP for altitude, speed and heading
    event_click_lock_alt(0);
    event_click_lock_speed(0);
    setprop("/autopilot/locks/heading",  '');
}

var event_click_lock_speed = func(do_enable)
{
    # do_enable == -1 : toggle
    if(do_enable == -1) {
        var is_ap_speed_locked = getprop("/autopilot/locks/speed") or '';
        do_enable = (is_ap_speed_locked == '') ? 1 : 0;
    }

    if(do_enable == 1) {
        setprop("/autopilot/locks/speed", 'speed-with-throttle');
    } else {
        setprop("/autopilot/locks/speed", '');
    }
}

var event_click_lock_alt = func(do_enable)
{
    # do_enable == -1 : toggle
    if(do_enable == -1) {
        var is_ap_alt_locked = getprop("/autopilot/locks/altitude") or '';
        do_enable = (is_ap_alt_locked == '') ? 1 : 0;
    }

    if(do_enable == 1) {
        setprop("/autopilot/locks/altitude", 'altitude-hold');
    } else {
        setprop("/autopilot/locks/altitude", '');
    }
    setprop("/autopilot/internal/target-climb-rate-fps", 0);
}



var inc_throttle = func() {

    var lock_speed = getprop("/autopilot/locks/speed") or '';
    if(lock_speed)
    {
        var node = props.globals.getNode("/autopilot/settings/target-speed-kt", 1);
        if(node.getValue() == nil)
        {
            node.setValue(0.0);
        }
        node.setValue(node.getValue() + arg[1]);
        if(node.getValue() < 0.0)
        {
            node.setValue(0.0);
        }
    }
    else
    {
        var thr0_value = getprop("/controls/engines/engine[0]/throttle") or 0;
        var thr1_value = getprop("/controls/engines/engine[1]/throttle") or 0;

        var new_thr0_value = thr0_value + arg[0];
        var new_thr1_value = thr1_value + arg[0];

        new_thr0_value = (new_thr0_value < -1.0) ? -1.0 : (new_thr0_value > 1.0) ? 1.0 : new_thr0_value;
        new_thr1_value = (new_thr1_value < -1.0) ? -1.0 : (new_thr1_value > 1.0) ? 1.0 : new_thr1_value;
        setprop("/controls/engines/engine[0]/throttle", new_thr0_value);
        setprop("/controls/engines/engine[1]/throttle", new_thr1_value);
    }
}

var inc_elevator = func() {

    var lock_alt = getprop("/autopilot/locks/altitude") or '';
    if(lock_alt == 'altitude-hold')
    {
        var node = props.globals.getNode("/autopilot/settings/target-altitude-ft", 1);
        if(node.getValue() == nil)
        {
            node.setValue(0.0);
        }
        node.setValue(node.getValue() + arg[1]);
        if(node.getValue() < 0)
        {
            node.setValue(0);
        }
        else if(node.getValue() > 40000)
        {
            node.setValue(40000);
        }
    }
    else
    {
        var elevator_value = getprop("/controls/flight/elevator") or 0;
        var new_elevator_value = elevator_value + arg[0];

        new_elevator_value = (new_elevator_value < -1.0) ? -1.0 : (new_elevator_value > 1.0) ? 1.0 : new_elevator_value;
        setprop("/controls/flight/elevator", new_elevator_value);
    }
}

var inc_aileron = func() {

    var lock_hdg = getprop("/autopilot/locks/heading") or '';
    if(lock_hdg == 'dg-heading-hold')
    {
        var node = props.globals.getNode("/autopilot/settings/heading-bug-deg", 1);
        if(node.getValue() == nil)
        {
            node.setValue(0.0);
        }
        node.setValue(node.getValue() + arg[1]);
        if(node.getValue() < 0)
        {
            node.setValue(node.getValue() + 360.0);
        }
        elsif(node.getValue() > 360.0)
        {
            node.setValue(node.getValue() - 360.0);
        }
    }
    else
    {
        var aileron_value = getprop("/controls/flight/aileron") or 0;
        var new_aileron_value = aileron_value + arg[0];

        new_aileron_value = (new_aileron_value < -1.0) ? -1.0 : (new_aileron_value > 1.0) ? 1.0 : new_aileron_value;
        setprop("/controls/flight/aileron", new_aileron_value);
    }
}

var center_flight_controls = func() {
    setprop("/controls/flight/elevator", 0);
    setprop("/controls/flight/aileron", 0);
    setprop("/controls/flight/rudder", 0);
}

var center_flight_controls_trim = func() {
    setprop("/controls/flight/elevator-trim", 0);
    setprop("/controls/flight/aileron-trim", 0);
    setprop("/controls/flight/rudder-trim", 0);
}


# setlistener("/sim/signals/fdm-initialized",init);
















