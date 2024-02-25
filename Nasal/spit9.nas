var alt = props.globals.getNode("instrumentation/altimeter/pressure-alt-ft");
var boost = props.globals.getNode("controls/engines/engine[0]/boost");
var blower = props.globals.getNode("controls/engines/engine[0]/blower");
var lowblower = 0.45;

#### Set boost level
var main_loop = func {

	if (alt.getValue() > 13700 and blower.getValue() == 0 ) {
		interpolate (boost, 1,30);
		blower.setValue(1);
		}
	if (alt.getValue() < 13700 and blower.getValue() == 1 ) {
		interpolate (boost, lowblower,30);
		blower.setValue(0);
		}
  settimer(main_loop, 0.2)
}

setlistener("/sim/signals/fdm-initialized", main_loop);


aircraft.steering.init();

var logo_dialog = gui.OverlaySelector.new("Select Logo", "Aircraft/Generic/Logos", "sim/model/logo/name", nil, "sim/multiplay/generic/string");
