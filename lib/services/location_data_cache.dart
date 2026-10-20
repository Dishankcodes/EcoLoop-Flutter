import '../api/api_manager.dart';
import '../models/location/city_model.dart';
import '../models/location/state_model.dart';

/// Shares successful location responses across screens during the app session.
/// Failed requests are not cached.
class LocationDataCache {
  LocationDataCache._();

  static final LocationDataCache instance = LocationDataCache._();

  List<StateModel>? _states;
  Future<List<StateModel>>? _statesRequest;

  final Map<String, List<CityModel>> _cities = {};
  final Map<String, Future<List<CityModel>>> _cityRequests = {};

  Future<List<StateModel>> getStates() async {
    final cached = _states;
    if (cached != null) return List.unmodifiable(cached);

    final pending = _statesRequest;
    if (pending != null) return List.unmodifiable(await pending);

    late final Future<List<StateModel>> request;

    request = _fetchStates().whenComplete(() {
      if (identical(_statesRequest, request)) {
        _statesRequest = null;
      }
    });

    _statesRequest = request;
    return List.unmodifiable(await request);
  }

  Future<List<StateModel>> _fetchStates() async {
    final response = await ApiManager().client.getStates('/locations/states');

    if (response.success != true || response.data == null) {
      throw Exception(response.error ?? 'Unable to load states.');
    }

    final result = List<StateModel>.unmodifiable(response.data!);
    _states = result;
    return result;
  }

  Future<List<CityModel>> getCities(String stateCode) async {
    final code = stateCode.trim();
    if (code.isEmpty) return const <CityModel>[];

    final cached = _cities[code];
    if (cached != null) return List.unmodifiable(cached);

    final pending = _cityRequests[code];
    if (pending != null) return List.unmodifiable(await pending);

    late final Future<List<CityModel>> request;

    request = _fetchCities(code).whenComplete(() {
      if (identical(_cityRequests[code], request)) {
        _cityRequests.remove(code);
      }
    });

    _cityRequests[code] = request;
    return List.unmodifiable(await request);
  }

  Future<List<CityModel>> _fetchCities(String stateCode) async {
    final response = await ApiManager().client.getCities(
      '/locations/cities',
      stateCode,
    );

    if (response.success != true || response.data == null) {
      throw Exception(response.error ?? 'Unable to load cities.');
    }

    final result = List<CityModel>.unmodifiable(response.data!);
    _cities[stateCode] = result;
    return result;
  }

  /// Optional: call if the location reference data changes.
  void clear() {
    _states = null;
    _cities.clear();
  }
}
