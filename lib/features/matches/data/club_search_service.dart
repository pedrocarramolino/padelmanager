import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class ClubSearchService {
  Future<List<String>> searchNearbyClubs() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permisos de ubicación denegados');
    }

    final position = await Geolocator.getCurrentPosition();

    final radius = 20000; // 20 km

    final query =
        '''
      [out:json];
      (
        node["sport"="padel"](around:$radius,${position.latitude},${position.longitude});
        way["sport"="padel"](around:$radius,${position.latitude},${position.longitude});

        node["leisure"="sports_centre"](around:$radius,${position.latitude},${position.longitude});
        way["leisure"="sports_centre"](around:$radius,${position.latitude},${position.longitude});

        node["club"](around:$radius,${position.latitude},${position.longitude});
        way["club"](around:$radius,${position.latitude},${position.longitude});
      );
      out center;
      ''';

    final url = Uri.parse('https://overpass-api.de/api/interpreter');

    final response = await http.post(url, body: query);

    if (response.statusCode != 200) {
      throw Exception('Error buscando clubes');
    }

    final data = jsonDecode(response.body);
    final Set<String> clubs = {};

    for (final item in data['elements']) {
      final tags = item['tags'];
      if (tags == null) continue;
      final name = tags['name'];
      if (name == null) continue;
      final clubName = name.toString().trim();
      if (clubName.length < 3) continue;
      clubs.add(clubName);
    }
    final result = clubs.toList();
    result.sort();
    return result;
  }
}
