print("*** LOADING b26.nas ... ***");

var sin = func(a) { math.sin(a * math.pi / 180.0) }
var cos = func(a) { math.cos(a * math.pi / 180.0) }

init = func {
  #print("=================== INIT ==========================");

  var engines_started = getprop("/sim/presets/engines_started") or 0;
  var is_onground = getprop("/sim/presets/onground") or 0;

  # starting airborn : start engines
  if (is_onground == 0)
  {
    engines_started = 1;
  }

  if(engines_started == 1)
  {
    setprop("/controls/engines/engine[0]/magnetos", 3);
    setprop("/engines/engine[0]/rpm", 800);
    setprop("/engines/engine[0]/running", 1);
    setprop("/controls/engines/engine[1]/magnetos", 3);
    setprop("/engines/engine[1]/rpm", 800);
    setprop("/engines/engine[1]/running", 1);

    setprop("/controls/electric/battery-switch", 1);
    setprop("/controls/switches/master-avionics", 1);
    setprop("/controls/light/nav", 1);
    setprop("/controls/light/taxi", 1);
    setprop("/controls/engines/engine[0]/fuel-pump", 1);
    setprop("/controls/engines/engine[1]/fuel-pump", 1);
    setprop("/sim/model/ground-equipment-f", 0);
    setprop("/sim/model/ground-equipment-p", 0);
    setprop("/sim/model/ground-equipment-g", 0);

    if (is_onground == 0)
    {
      # IF IN AIR :
      setprop("/controls/gear/brake-parking", 0);
      #setprop("/autopilot/settings/target-speed-kt", getprop("/sim/presets/airspeed-kt"));
      #setprop("/autopilot/settings/target-altitude-ft", getprop("/sim/presets/altitude-ft"));
      #setprop("/autopilot/settings/heading-bug-deg", getprop("/sim/presets/heading-deg"));
      #setprop("/autopilot/locks/speed", "speed-with-throttle");
      #setprop("/autopilot/locks/heading", "dg-heading-hold");
      #setprop("/autopilot/locks/altitude", "altitude-hold");

      settimer(func() {
        event_click_hold_autopilot();
      }, 1);

    }
    settimer(func() {
      check_if_lights_needed();
    }, 10);
  }
  else
  {
    setprop("/autopilot/locks/heading" , "none");
    setprop("/autopilot/locks/altitude" , "none");
  }

  main_loop();
}

check_if_lights_needed = func {
      var luminosity = getprop("/rendering/scene/diffuse/green");
      if (luminosity < .5) {
          setprop("/controls/light/cabin-norm", 1);
          setprop("/controls/light/panel-norm", 1);
          setprop("/controls/light/instrument-norm", 1);
          setprop("/controls/light/landing", 1);
      }
}

main_loop = func {
  #print("=================== LOOP ==========================");

  # on retire les ground equipments si on bouge
  var groundspeed = getprop("/velocities/groundspeed-kt") or 0;
  if (groundspeed > 0.2)
  {
    setprop("/sim/model/ground-equipment-g", 0);
    setprop("/sim/model/ground-equipment-p", 0);
    setprop("/sim/model/ground-equipment-f", 0);
  }

  # on regarde si on a du courant
  var engine0_running = getprop("/engines/engine[0]/running") or 0;
  var engine1_running = getprop("/engines/engine[1]/running") or 0;
  var battery_on = getprop("/controls/electric/battery-switch") or 0;
  var epu_on = getprop("/sim/model/ground-equipment-p") or 0;
  var systems_electrical_on = 0;
  if (engine0_running or engine1_running or battery_on or epu_on)
  {
    systems_electrical_on = 1;
  }
  else
  {
    systems_electrical_on = 0;
  }
  setprop("/systems/electrical/on", systems_electrical_on);

  # on permet le demarrage si on a du courant
  if (systems_electrical_on)
  {
    var engine0_do_start = getprop("/controls/engines/engine[0]/do_start") or 0;
    setprop("/controls/engines/engine[0]/starter", engine0_do_start);
    var engine1_do_start = getprop("/controls/engines/engine[1]/do_start") or 0;
    setprop("/controls/engines/engine[1]/starter", engine1_do_start);
  }

  # permet de jouer le son de shutdown
  var engine0_stopped = getprop("/engines/engine[0]/stopped") or 0;
  var engine0_shutdown = getprop("/engines/engine[0]/shutdown") or 0;
  if ((engine0_running == 0) and (engine0_stopped == 0))
  {
    setprop("/engines/engine[0]/shutdown", 1);
    setprop("/engines/engine[0]/stopped", 1);
    settimer(func() {
      setprop("/engines/engine[0]/shutdown", 0);
    }, 8);
  }
  if ((engine0_running == 1) and (engine0_stopped == 1))
  {
    setprop("/engines/engine[0]/stopped", 0);
  }
  var engine1_stopped = getprop("/engines/engine[1]/stopped") or 0;
  var engine1_shutdown = getprop("/engines/engine[1]/shutdown") or 0;
  if ((engine1_running == 0) and (engine1_stopped == 0))
  {
    setprop("/engines/engine[1]/shutdown", 1);
    setprop("/engines/engine[1]/stopped", 1);
    settimer(func() {
      setprop("/engines/engine[1]/shutdown", 0);
    }, 8);
  }
  if ((engine1_running == 1) and (engine1_stopped == 1))
  {
    setprop("/engines/engine[1]/stopped", 0);
  }


  settimer(main_loop, 0.05);
}

var event_start_engine = func(held)
{
  if (held == 1)
  {
    setprop("/controls/engines/engine[0]/do_start" , 1);
    setprop("/controls/engines/engine[1]/do_start" , 1);
    setprop("/controls/engines/engine[0]/starter" , 1);
    setprop("/controls/engines/engine[1]/starter" , 1);
  }
  elsif (held == 0)
  {
    setprop("/controls/engines/engine[0]/do_start" , 0);
    setprop("/controls/engines/engine[1]/do_start" , 0);
  }

  settimer(func() {
    setprop("/controls/engines/engine[0]/starter" , 0);
    setprop("/controls/engines/engine[1]/starter" , 0);
  }, 2);

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
    center_flight_controls();
    center_flight_controls_trim();
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
        center_flight_controls();
        center_flight_controls_trim();
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


setlistener("/sim/signals/fdm-initialized", init);
















