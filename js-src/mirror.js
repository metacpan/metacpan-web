import {Map, Feature, View} from 'ol';
import Point from 'ol/geom/Point';
import TileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import {fromLonLat} from 'ol/proj';
import OSM from 'ol/source/OSM';
import VectorSource from 'ol/source/Vector';
import Fill from 'ol/style/Fill';
import StrokeStyle from 'ol/style/Stroke';
import Style from 'ol/style/Style';
import CircleStyle from 'ol/style/Circle';

document.addEventListener('DOMContentLoaded', function(){
  $('#map').width("auto");
  var dotFeatures = mirror_dots.map(
    d => new Feature(new Point(fromLonLat( d )))
  );
  var dotSource = new VectorSource({ features: dotFeatures });
  var style = new Style({
    image: new CircleStyle({
      radius: 4,
      fill: new Fill({ color: '#BAD3EA' }),
      stroke: new StrokeStyle({ color: '#36C', width: 1 }),
    }),
    zIndex: Infinity,
  });
  var map = new Map({
    target: 'map',
    layers: [
      new TileLayer({source: new OSM()}),
      new VectorLayer({ source: dotSource, style: style }),
    ],
    view: new View({ center: fromLonLat([ 14,35 ]), zoom: 2 }),
  });
});
