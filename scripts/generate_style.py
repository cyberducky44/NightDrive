#!/usr/bin/env python3
"""Generate NightDrive's original OpenMapTiles style (no game assets)."""
import json
from pathlib import Path

layers = []
def layer(id, type, source_layer=None, **kwargs):
    item = dict(id=id, type=type)
    if source_layer:
        item.update(source='openmaptiles', **{'source-layer': source_layer})
    item.update(kwargs)
    layers.append(item)

def zoom(*stops):
    return ['interpolate', ['linear'], ['zoom'], *stops]

layer('night', 'background', paint={'background-color': '#060b1c'})
layer('landcover', 'fill', 'landcover', paint={'fill-color': '#0a1529', 'fill-opacity': 0.65})
layer('parks', 'fill', 'landuse', filter=['in', 'class', 'park', 'grass', 'cemetery', 'recreation_ground'], paint={'fill-color': '#0d2430'})
layer('water', 'fill', 'water', paint={'fill-color': '#030713'})
layer('waterway', 'line', 'waterway', paint={'line-color': '#15344b', 'line-width': zoom(10,0.4,16,2)})
layer('boundary', 'line', 'boundary', paint={'line-color':'#43516b','line-width':0.7,'line-dasharray':[3,3],'line-opacity':0.5})
layer('building-footprints', 'fill', 'building', minzoom=13, paint={'fill-color':'#8d123c','fill-outline-color':'#d62b50','fill-opacity':0.85})
# A cyan outer road with dark inner pavement preserves the reference's outlined street grid.
for category, classes, width in [
    ('paths',['path','track'],[12,0.3,16,1.8,20,7]),
    ('local',['minor','service'],[10,0.3,14,1.8,16,5,20,28]),
    ('main',['primary','secondary','tertiary'],[6,0.4,12,1.8,16,8,20,40]),
    ('highway',['motorway','trunk'],[5,0.5,12,2.4,16,10,20,48])
]:
    road_filter=['in','class',*classes]
    layer(category+'-glow','line','transportation',filter=road_filter,layout={'line-cap':'round','line-join':'round'},paint={'line-color':'#17b9d0','line-width':zoom(*[v if i%2==0 else v+3 for i,v in enumerate(width)]),'line-opacity':0.14,'line-blur':2})
    layer(category+'-edge','line','transportation',filter=road_filter,layout={'line-cap':'round','line-join':'round'},paint={'line-color':'#51d6e7','line-width':zoom(*width),'line-opacity':0.9})
    layer(category+'-pavement','line','transportation',filter=road_filter,layout={'line-cap':'round','line-join':'round'},paint={'line-color':'#123248','line-width':zoom(*[v if i%2==0 else max(0,v-1.8) for i,v in enumerate(width)])})
layer('rail','line','transportation',filter=['==','class','rail'],paint={'line-color':'#5a6686','line-width':1,'line-dasharray':[2,3]})
layer('buildings-3d','fill-extrusion','building',minzoom=14,filter=['!=','hide_3d',True],paint={
    'fill-extrusion-color':'#8f193a',
    'fill-extrusion-height':['coalesce',['get','render_height'],6],
    'fill-extrusion-base':['coalesce',['get','render_min_height'],0],
    'fill-extrusion-opacity':0.96,
    'fill-extrusion-vertical-gradient':True
})
layer('street-names','symbol','transportation_name',minzoom=13,layout={
    'symbol-placement':'line','text-field':['coalesce',['get','name:en'],['get','name']],
    'text-font':['Noto Sans Regular'],'text-size':zoom(13,10,18,13),'text-letter-spacing':0.06,
    'text-max-angle':35,'symbol-spacing':260
},paint={'text-color':'#a7e3ef','text-halo-color':'#071222','text-halo-width':1.5})
layer('major-road-names','symbol','transportation_name',minzoom=12,filter=['in','class','primary','motorway','trunk'],layout={
    'symbol-placement':'line','text-field':['coalesce',['get','name:en'],['get','name']],
    'text-font':['Noto Sans Bold'],'text-size':12,'text-transform':'uppercase','text-letter-spacing':0.08
},paint={'text-color':'#f2cf70','text-halo-color':'#071222','text-halo-width':1.5})
layer('places','symbol','place',layout={
    'text-field':['coalesce',['get','name:en'],['get','name']],
    'text-font':['Noto Sans Bold'],'text-size':zoom(3,11,10,15,15,18),
    'text-transform':'uppercase','text-letter-spacing':0.15,'text-max-width':10
},paint={'text-color':'#d0eaf2','text-halo-color':'#060b1c','text-halo-width':2})
style = {
    'version':8,'name':'NightDrive / Neon Grid',
    'metadata':{'nightdrive:version':1,'nightdrive:author':'NightDrive'},
    'sources':{'openmaptiles':{'type':'vector','url':'https://tiles.openfreemap.org/planet','attribution':'<a href="https://openfreemap.org">OpenFreeMap</a> © <a href="https://openmaptiles.org">OpenMapTiles</a> © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'}},
    'glyphs':'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf',
    'light':{'anchor':'viewport','color':'#fff3ef','intensity':0.3,'position':[1.5,210,45]},
    'layers':layers
}
path = Path(__file__).resolve().parents[1] / 'NightDrive/Resources/nightdrive.json'
path.write_text(json.dumps(style,indent=2)+'\n')
print(f'Wrote {len(layers)} layers to {path.name}')
