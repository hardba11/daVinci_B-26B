print("*** LOADING lights - lights.nas ... ***");

# namespace : lights

# management of blinking
var strobe = aircraft.light.new("/sim/model/lights/strobe", [0.05, 0.1, 0.05, 1]);
strobe.switch(0);

var beacon = aircraft.light.new("/sim/model/lights/beacon", [0.1, 0.8]);
beacon.switch(0);

var lights = func()
{
    strobe.switch(getprop("/controls/light/nav"));
    beacon.switch(getprop("/controls/light/nav"));
    settimer(lights, 2);
}


var light = func()
{
    var is_gear_down  = getprop("gear/gear[0]/position-norm") or 0;
    var is_taxi_on    = getprop("/controls/light/taxi") or 0;
    var is_landing_on = getprop("/controls/light/landing") or 0;
    var is_on         = (is_taxi_on and is_gear_down) or is_landing_on;

    var lat_to_m = 110952;

    var data_light = [
        {
            'x': 60.0,
            'y': 0.0,
            'z': 0.4,
            'size': 12,
            'stretch': 4.5,
        },
        {
            'x': 11.0,
            'y': 0.0,
            'z': 0.4,
            'size': 7,
            'stretch': 1.8,
        },
    ];

    setprop("/sim/rendering/als-secondary-lights/num-lightspots", size(data_light));
    #setprop("/controls/lighting/landing-lights", is_on);

    # enable als lights if switch on and gear up and bus on
    if(is_on)
    {
        var luminosity = getprop("/rendering/scene/diffuse/green");
        var intensity = 1 - luminosity;
        intensity = (intensity > .9) ? .9 : intensity;

        var aircraft_position = geo.aircraft_position();
        var lat = aircraft_position.lat();
        var lon = aircraft_position.lon();
        var alt = aircraft_position.alt();
        var viewer_position = geo.viewer_position();
        var gear_agl = getprop("/position/gear-agl-ft") or 0;
        var proj_x = gear_agl;
        var proj_z = gear_agl / 10.0;
        var lon_to_m = math.cos(lat * math.pi / 180.0) * lat_to_m;
        var delta_x = (lat - viewer_position.lat()) * lat_to_m;
        var delta_y = -(lon - viewer_position.lon()) * lon_to_m;
        var delta_z = alt - proj_z - viewer_position.alt();
        var heading = getprop("/orientation/heading-deg") * math.pi / 180.0;
        var x_factor = math.sin(heading);
        var y_factor = math.cos(heading);

        for(var i = 0; i < size(data_light); i += 1)
        {
            aircraft_position.set_lat(lat + (((data_light[i]['x'] + proj_x) * y_factor) + (data_light[i]['y'] * x_factor)) / lat_to_m);
            aircraft_position.set_lon(lon + (((data_light[i]['x'] + proj_x) * x_factor )- (data_light[i]['y'] * y_factor)) / lon_to_m);
            delta_x = (aircraft_position.lat() - viewer_position.lat()) * lat_to_m;
            delta_y = -(aircraft_position.lon() - viewer_position.lon()) * lon_to_m;

            setprop("/sim/rendering/als-secondary-lights/lightspot/size["~ i ~"]", data_light[i]['size']);
            setprop("/sim/rendering/als-secondary-lights/lightspot/stretch["~ i ~"]", data_light[i]['stretch']);

            setprop("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m["~ i ~"]", delta_x);
            setprop("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m["~ i ~"]", delta_y);
            setprop("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m["~ i ~"]", delta_z);
            setprop("/sim/rendering/als-secondary-lights/lightspot/dir["~ i ~"]", heading);

            setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r["~ i ~"]", intensity);
            setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g["~ i ~"]", intensity);
            setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b["~ i ~"]", intensity + (intensity / 10));
        }
    }
    else
    {
        for(var i = 0; i < size(data_light); i += 1)
        {
            setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r["~ i ~"]", .0);
            setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g["~ i ~"]", .0);
            setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b["~ i ~"]", .0);
        }
    }
    settimer(light, .1);
}


setlistener("sim/signals/fdm-initialized", lights);
#setlistener("sim/signals/fdm-initialized", light);

