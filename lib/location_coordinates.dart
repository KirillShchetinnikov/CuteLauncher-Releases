enum ManualLocationInput { city, coordinates }

typedef LocationCoordinates = ({double latitude, double longitude});

LocationCoordinates? coordinatesFrom(Object? latitude, Object? longitude) {
  if (latitude is! num ||
      longitude is! num ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180) {
    return null;
  }
  return (latitude: latitude.toDouble(), longitude: longitude.toDouble());
}

ManualLocationInput? decodeManualLocationInput(Object? value) {
  if (value == null) return null;
  for (final input in ManualLocationInput.values) {
    if (value == input.name) return input;
  }
  throw const FormatException('Invalid manual location input');
}

LocationCoordinates? decodeLocationCoordinates(Object? value) {
  if (value == null) return null;
  if (value is Map) {
    final coordinates = coordinatesFrom(value['latitude'], value['longitude']);
    if (coordinates != null) return coordinates;
  }
  throw const FormatException('Invalid location coordinates');
}

Map<String, double> encodeLocationCoordinates(
  LocationCoordinates coordinates,
) => {'latitude': coordinates.latitude, 'longitude': coordinates.longitude};
