import '../services/api.service.dart';
import '../models/schedule.model.dart';
import '../utils/error_handler.dart';

class ScheduleRepository {
  final _api = ApiService();

  Future<List<ScheduleModel>> getAll() async {
    try {
      final response = await _api.get('/horarios');
      final list     = response.data['data'] as List;
      return list.map((e) => ScheduleModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception(handleError(e).mensaje);
    }
  }

  Future<ScheduleModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/horarios', data);
      return ScheduleModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception(handleError(e).mensaje);
    }
  }

  Future<void> toggle(int id, bool activo) async {
    try {
      await _api.put('/horarios/$id', {'activo': activo});
    } catch (e) {
      throw Exception(handleError(e).mensaje);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _api.delete('/horarios/$id');
    } catch (e) {
      throw Exception(handleError(e).mensaje);
    }
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    try {
      await _api.put('/horarios/$id', data);
    } catch (e) {
      throw Exception(handleError(e).mensaje);
    }
  }
}