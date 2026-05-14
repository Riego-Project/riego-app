import '../services/api.service.dart';
import '../models/valve.model.dart';

class ValveRepository {
  final _api = ApiService();

  Future<List<ValveModel>> getAll() async {
    final response = await _api.get('/valvulas');
    final list     = response.data['data'] as List;
    return list.map((e) => ValveModel.fromJson(e)).toList();
  }

  Future<void> sendCommand(String valveId, String accion) async {
    await _api.post('/valvulas/$valveId/comando', { 'accion': accion });
  }

  Future<void> sendZoneCommand(int zoneId, String accion) async {
    await _api.post('/valvulas/zona/$zoneId/comando', { 'accion': accion });
  }
}