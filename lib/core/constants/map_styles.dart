class MapStyles {
  static const String darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0a1128"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8b9dc3"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0a1128"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#cbd5e1"}]},
  {"featureType": "poi", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1e293b"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a3f"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca3af"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c3e50"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2937"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f3f4f6"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f172a"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#515c6d"}]},
  {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#17263c"}]}
]
''';
}
