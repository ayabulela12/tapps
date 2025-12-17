import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/models/weather.dart';
import 'package:appmaniazar/services/api_helper.dart';


final weatherByCityNameProvider = FutureProvider.autoDispose.family<Weather, String>((ref, String cityName) {
  return ApiHelper.getWeatherByCityName(cityName);
});