import '../services/api.service.dart';
import '../models/valve.model.dart';
import '../utils/error_handler.dart';

class ValveRepository {
  final _api = ApiService();

  Future<List<ValveModel>> getAll() async {
    try {
      final response = await _api.get('/valvulas');
      final list     = response.data['data'] as List;
      return list.map((e) => ValveModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception(handleError(e).mensaje);
    }
  }

  Future<void> sendCommand(String valveId, String accion) async {
    try {
      await _api.post('/valvulas/$valveId/comando', {'accion': accion});
    } catch (e) {
      throw Exception(handleError(e).mensaje);
    }
  }

  Future<void> sendZoneCommand(int zoneId, String accion) async {
    try {
      await _api.post('/valvulas/zona/$zoneId/comando', {'accion': accion});
    } catch (e) {
      throw Exception(handleError(e).mensaje);
    }
  }
}