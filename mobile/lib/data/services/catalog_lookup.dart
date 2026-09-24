import 'package:get/get.dart';
import '../providers/api_client.dart';
import '../providers/catalog_provider.dart';

class CatalogLookup {
  CatalogLookup._();

  static bool _loaded = false;
  static Map<int, String> _specNames = {};
  static Map<int, Map<String, dynamic>> _courseMeta = {};

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final api = Get.find<ApiClient>();
      final provider = CatalogProvider(api);
      final results = await Future.wait([
        provider.getSpecializations(),
        provider.getCourses(),
      ]);

      final specData = results[0].data['data'];
      if (specData is List) {
        _specNames = {
          for (final e in specData)
            (e['id'] as num?)?.toInt() ?? 0: (e['name'] ?? '').toString()
        };
        _loaded = true;
      }

      final coursesData = results[1].data['data'];
      if (coursesData is List) {
        _courseMeta = {
          for (final e in coursesData)
            (e['id'] as num?)?.toInt() ?? 0: Map<String, dynamic>.from(e as Map)
        };
        _loaded = true;
      }
    } catch (_) {
      // يبقى فارغاً — تُعرض البيانات كما هي بدون إثراء
    }
  }

  static String specName(int specializationId) =>
      _specNames[specializationId] ?? '';

  static Map<String, dynamic>? metaFor(int courseId) => _courseMeta[courseId];

  static Map<String, dynamic> enrichJson(Map<String, dynamic> json) {
    final courseId = (json['id'] ?? json['course_id'] ?? 0) as num;
    final meta = _courseMeta[courseId.toInt()];
    if (meta == null) return json;

    if ((json['specialization_id'] ?? 0) == 0 &&
        meta['specialization_id'] != null) {
      json['specialization_id'] = meta['specialization_id'];
    }
    if ((json['specialization_name'] == null ||
            json['specialization_name'] == '') &&
        meta['specialization_id'] != null) {
      json['specialization_name'] =
          _specNames[(meta['specialization_id'] as num).toInt()] ?? '';
    }
    if ((json['year'] ?? 0) == 0 && meta['year'] != null) {
      json['year'] = meta['year'];
    }
    if ((json['price'] == null || json['price'] == '' || json['price'] == '0.00') &&
        meta['price'] != null) {
      json['price'] = meta['price'];
    }
    return json;
  }
}
