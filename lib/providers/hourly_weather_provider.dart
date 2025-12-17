import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/services/api_helper.dart';


final hourlyWeatherProvider = FutureProvider.autoDispose((ref) async {
  return ApiHelper.getHourlyForecast();
});