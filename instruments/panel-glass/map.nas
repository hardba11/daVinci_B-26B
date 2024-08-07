print("*** LOADING map.nas ... ***");

# namespace : map

# thx viggen and m2000-5 dev teams ! ;)
#
# url where to take the tiles
# Some alternative can exist
# http://otile1.mqcdn.com/tiles/1.0.0/map
# http://otile1.mqcdn.com/tiles/1.0.0/sat
# (also see https://operations.osmfoundation.org/policies/tiles/)
#var makeUrl  = string.compileTemplate('http://{server}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.jpg');
#var servers = ["otile1", "otile2", "otile3", "otile4"];

var width = 1024;
var height = 1024;

var MAP = {
    canvas_settings: {
        'name': 'map',
        'size': [1024, 1024],
        'view': [width, height],
        'mipmapping': 1
    },
    new: func(placement)
    {
        var m = {
            parents: [MAP],
            canvas: canvas.new(MAP.canvas_settings)
        };

# INIT PROPERTIES

        # data used to create array of tiles
        m.tile_size = 256;
        m.num_tiles = [7, 7];
        m.center_tile_offset = [2, 2];
        m.type = 'map';

        # my aircraft data and settings
        m.myHeadingProp = props.globals.getNode("orientation/heading-deg");
        m.myCoord = geo.aircraft_position();
        m.zoom = 6;

        # used where to get and store locally tiles files
        m.home =  props.globals.getNode("/sim/fg-home");
        m.maps_base = m.home.getValue() ~'/cache/maps';
        m.makeUrl  = string.compileTemplate('http://{server}.tile.osm.org/{z}/{x}/{y}.png');
        m.servers = ['a', 'b', 'c'];
        m.makePath = string.compileTemplate(m.maps_base ~'/osm-{type}/{z}/{x}/{y}.png');
        m.filename = 'Aircraft/panthera/instruments/map/my_aircraft_icon.svg';

# CANVAS STUFF

        # main canvas
        m.canvas.addPlacement(placement);
        m.root = m.canvas.createGroup();

        # text for MAP page
        m.txt_zoom = m.root.createChild('text', 'txt_zoom')
            .setTranslation(200, 70)
            .setAlignment('left-bottom')
            .setFont('LiberationFonts/LiberationSansNarrow-Bold.ttf')
            .setFontSize(40)
            .setColor(.8, 0, 0, 1)
            .setText('txt_zoom')
            .set('z-index', 1);
        m.txt_gps_wpt = m.root.createChild('text', 'txt_gps_wpt')
            .setTranslation(700, 70)
            .setAlignment('left-bottom')
            .setFont('LiberationFonts/LiberationSansNarrow-Bold.ttf')
            .setFontSize(46)
            .setColor(0, 0, 0, 1)
            .setText('txt_gps_wpt')
            .set('z-index', 1);
        m.txt_gps_bearing = m.root.createChild('text', 'txt_gps_bearing')
            .setTranslation(700, 130)
            .setAlignment('left-bottom')
            .setFont('LiberationFonts/LiberationSansNarrow-Bold.ttf')
            .setFontSize(46)
            .setColor(0, 0, 0, 1)
            .setText('txt_gps_bearing')
            .set('z-index', 1);
        m.txt_gps_distance = m.root.createChild('text', 'txt_gps_distance')
            .setTranslation(700, 190)
            .setAlignment('left-bottom')
            .setFont('LiberationFonts/LiberationSansNarrow-Bold.ttf')
            .setFontSize(46)
            .setColor(0, 0, 0, 1)
            .setText('txt_gps_distance')
            .set('z-index', 1);
        m.txt_gps_eta = m.root.createChild('text', 'txt_gps_eta')
            .setTranslation(700, 250)
            .setAlignment('left-bottom')
            .setFont('LiberationFonts/LiberationSansNarrow-Bold.ttf')
            .setFontSize(46)
            .setColor(0, 0, 0, 1)
            .setText('txt_gps_eta')
            .set('z-index', 1);
        m.txt_coords_lat = m.root.createChild('text', 'txt_coords_lat')
            .setTranslation(180, 850)
            .setAlignment('left-bottom')
            .setFont('LiberationFonts/LiberationSansNarrow-Bold.ttf')
            .setFontSize(40)
            .setColor(.8, 0, 0, 1)
            .setText('txt_coords_lat')
            .set('z-index', 1);
        m.txt_coords_lng = m.root.createChild('text', 'txt_coords_lng')
            .setTranslation(180, 900)
            .setAlignment('left-bottom')
            .setFont('LiberationFonts/LiberationSansNarrow-Bold.ttf')
            .setFontSize(40)
            .setColor(.8, 0, 0, 1)
            .setText('txt_coords_lng')
            .set('z-index', 1);
        m.txt_hdg = m.root.createChild('text', 'txt_hdg')
            .setTranslation(180, 950)
            .setAlignment('left-bottom')
            .setFont('LiberationFonts/LiberationSansNarrow-Bold.ttf')
            .setFontSize(32)
            .setColor(.8, 0, 0, 1)
            .setText('txt_hdg')
            .set('z-index', 1);
        m.txt_alt = m.root.createChild('text', 'txt_alt')
            .setTranslation(600, 900)
            .setAlignment('left-bottom')
            .setFont('LiberationFonts/LiberationSansNarrow-Bold.ttf')
            .setFontSize(40)
            .setColor(.8, 0, 0, 1)
            .setText('txt_alt')
            .set('z-index', 1);

        m.g_map = m.root.createChild('group');
        m.root.setCenter(width / 2, height / 2); # center of the canvas

        # simple aircraft icon at current position/center of the map
        m.svg_symbol = m.root.createChild('group');
        canvas.parsesvg(m.svg_symbol, m.filename);
        m.svg_symbol.setScale(0.1);
        m.svg_symbol.setTranslation((width / 2) - 40, (height / 2) - 40);
        m.myVector = m.svg_symbol.getBoundingBox();
        m.svg_symbol.updateCenter();
        m.svg_symbol.set('z-index', 1);

        # map tiles
        var make_tiles = func(canvas_group) {
            var tiles = setsize([], m.num_tiles[0]);
            for(var x = 0; x < m.num_tiles[0]; x += 1)
            {
                tiles[x] = setsize([], m.num_tiles[1]);
                for(var y = 0; y < m.num_tiles[1]; y += 1)
                {
                    tiles[x][y] = canvas_group.createChild('image', 'map-tile');
                }
            }
            return tiles;
        }

        m.tiles_map = make_tiles(m.g_map);
        m.last_tile = [-1, -1];
        m.last_type = m.type;

        return m;
    },
    update: func(type) {
        var serviceable = getprop("/instrumentation/my_aircraft/map/controls/serviceable") or 0;
        var time_speed = getprop("/sim/speed-up") or 1;
        var loop_speed = (time_speed == 1) ? 1 : 4 * time_speed;

        var zoom = getprop("/instrumentation/my_aircraft/map/controls/zoom_primary") or 6;
        if(type == 'secondary')
        {
            zoom = getprop("/instrumentation/my_aircraft/map/controls/zoom_secondary") or 6;
        }

        if(serviceable == 1)
        {
            me.svg_symbol.setRotation(me.myHeadingProp.getValue() * D2R);
            me.zoom = zoom;

            me.txt_coords_lat.setText(sprintf('%s', getprop("/position/latitude-string") or ''));
            me.txt_coords_lng.setText(sprintf('%s', getprop("/position/longitude-string") or ''));
            me.txt_alt.setText(sprintf('alt agl : %d ft', getprop("/position/altitude-agl-ft") or 0));
            me.txt_hdg.setText(sprintf('heading true : %d - heading mag : %d', getprop("/orientation/heading-deg") or 0, getprop("/orientation/heading-magnetic-deg") or 0));
            me.txt_zoom.setText(sprintf('zoom : %s', me.zoom));

            var gps_wpt  = getprop("/instrumentation/gps/wp/wp[1]/ID") or '---';
            var gps_brg  = '---';
            var gps_dist = '---';
            var gps_eta  = '---';
            var gps_mode = getprop("/instrumentation/gps/mode") or '';
            if(((gps_mode == 'dto') or (gps_mode == 'obs')) and (gps_wpt != '---'))
            {
                gps_wpt  = getprop("/instrumentation/gps/wp/wp[1]/ID") or '---';
                gps_brg  = sprintf('%d', getprop("/instrumentation/gps/wp/wp[1]/bearing-true-deg") or 0);
                gps_dist = sprintf('%.2f', getprop("/instrumentation/gps/wp/wp[1]/distance-nm") or 0);
                gps_eta  = getprop("/instrumentation/gps/wp/wp[1]/TTW") or '---';
            }
            me.txt_gps_wpt.setText(sprintf('WPT : %s', gps_wpt));
            me.txt_gps_bearing.setText(sprintf('BRG : %s', gps_brg));
            me.txt_gps_distance.setText(sprintf('DIST : %s', gps_dist));
            me.txt_gps_eta.setText(sprintf('ETA : %s', gps_eta));

            # getting position
            me.myCoord = geo.aircraft_position();
            lat = me.myCoord.lat();
            lon = me.myCoord.lon();

            # getting tile number (x, y) from lat/lng
            var n = math.pow(2, me.zoom);
            var offset = [
                (n * (lon + 180) / 360) - me.center_tile_offset[0],
                ((1 - math.ln(math.tan(lat * D2R) + (1 / math.cos(lat * D2R))) / math.pi) / 2 * n) - me.center_tile_offset[1]
            ];
            var tile_index = [int(offset[0]), int(offset[1])];
            var ox = tile_index[0] - offset[0];
            var oy = tile_index[1] - offset[1];

            # placing tiles
            for(var x = 0; x < me.num_tiles[0]; x += 1)
            {
                for(var y = 0; y < me.num_tiles[1]; y += 1)
                {
                    me.tiles_map[x][y].setTranslation(
                        int(((ox + x) * me.tile_size)),
                        int(((oy + y) * me.tile_size))
#                        int(((ox + x) * me.tile_size) +18),
#                        int(((oy + y) * me.tile_size) +13)
                    );
                }
            }

            # downloading, using and displaying tiles
            if(tile_index[0] != me.last_tile[0]
                or tile_index[1] != me.last_tile[1]
                or me.type != me.last_type)
            {
                for(var x = 0; x < me.num_tiles[0]; x += 1)
                {
                    for(var y = 0; y < me.num_tiles[1]; y += 1)
                    {
                        var server_index = math.round(rand() * (size(me.servers) - 1));
                        var server_name = me.servers[server_index];
                        var pos = {
                            z: me.zoom,
                            x: tile_index[0] + x,
                            y: tile_index[1] + y,
                            type: me.type,
                            server: server_name
                        };
                        (func() {
                            var img_path = me.makePath(pos);
                            if(io.stat(img_path) == nil)
                            {
                                var img_url = me.makeUrl(pos);
                                http.save(img_url, img_path)
                                    .done(func() {
                                        printf('::map - downloading %s to %s', img_url, img_path);
                                    })
                                    .fail(func(r) {
                                        printf('::map - FAILED downloading %s to %s', img_url, img_path);
                                        me.tiles_map[x - 1][y - 1].setFile("");
                                    });
                            }
                            else
                            {
                                if(pos.z == me.zoom)
                                {
                                    #printf('::map - using %s', img_path);
                                    me.tiles_map[x][y].setFile(img_path);
                                }
                            }
                        })();
                    }
                }
                me.last_tile = tile_index;
                me.last_type = me.type;
            }
        }
        loop_speed = (time_speed == 1) ? .5 : 4;

        settimer(func() { me.update(type); }, loop_speed);
    },
};

var init = setlistener("/sim/signals/fdm-initialized", func() {
    removelistener(init); # only call once
    var my_map = MAP.new({'node': 'center.top_screen'});
    my_map.update('primary');
    var my_map_little = MAP.new({'node': 'center.bottom_screen'});
    my_map_little.update('secondary');
});

