import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/site_model.dart';

class SiteLocalDatasource {
  Box<SiteModel> get _box => Hive.box<SiteModel>(HiveBoxes.sites);

  Future<void> saveSite(SiteModel site) async {
    await _box.put(site.id, site);
  }

  SiteModel? getSiteById(String id) {
    return _box.get(id);
  }

  List<SiteModel> getAllSites() {
    return _box.values.toList();
  }

  Future<void> deleteSite(String id) async {
    await _box.delete(id);
  }

  bool get isEmpty => _box.isEmpty;
}
