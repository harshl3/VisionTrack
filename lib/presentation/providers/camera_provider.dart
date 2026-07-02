import 'package:flutter/foundation.dart';
import '../../core/services/camera_api_service.dart';
import '../../data/models/camera.dart';
import 'auth_provider.dart';

class CameraProvider with ChangeNotifier {
  final AuthProvider authProvider;

  CameraProvider(this.authProvider);

  List<Camera> _cameras = [];
  List<SurveyorUser> _surveyors = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  double? _minRange;
  double? _maxRange;
  int? _selectedSurveyorId;
  DateTime? _fromDate;
  DateTime? _toDate;

  List<Camera> get cameras => _cameras;
  List<SurveyorUser> get surveyors => _surveyors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get searchQuery => _searchQuery;
  double? get minRange => _minRange;
  double? get maxRange => _maxRange;
  int? get selectedSurveyorId => _selectedSurveyorId;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;

  int get totalCameras => _cameras.length;
  int get activeCameras => _cameras.where((c) => c.isActive).length;
  int get recentlyAddedCameras =>
      _cameras.where((c) => DateTime.now().difference(c.createdAt).inDays <= 7).length;

  List<Camera> get filteredCameras {
    var list = List<Camera>.from(_cameras);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((c) =>
              c.ownerName.toLowerCase().contains(q) ||
              c.cameraName.toLowerCase().contains(q) ||
              c.contactNumber.contains(q))
          .toList();
    }

    if (_minRange != null) {
      list = list.where((c) => c.cameraRange >= _minRange!).toList();
    }
    if (_maxRange != null) {
      list = list.where((c) => c.cameraRange <= _maxRange!).toList();
    }
    if (_selectedSurveyorId != null) {
      list = list.where((c) => c.createdBy == _selectedSurveyorId).toList();
    }
    if (_fromDate != null) {
      list = list.where((c) => !c.createdAt.isBefore(_fromDate!)).toList();
    }
    if (_toDate != null) {
      list = list.where((c) => !c.createdAt.isAfter(_toDate!)).toList();
    }

    return list;
  }

  Future<void> loadCameras() async {
    final token = authProvider.token;
    if (token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cameras = await CameraApiService.fetchCameras(
        token: token,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        minRange: _minRange,
        maxRange: _maxRange,
        surveyorId: _selectedSurveyorId,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Camera load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSurveyors() async {
    final token = authProvider.token;
    if (token == null || !authProvider.isAdmin) return;

    try {
      _surveyors = await CameraApiService.fetchSurveyors(token: token);
      notifyListeners();
    } catch (e) {
      debugPrint('Surveyor load error: $e');
    }
  }

  Future<bool> addCamera(Map<String, dynamic> payload) async {
    final token = authProvider.token;
    if (token == null) return false;

    try {
      final camera = await CameraApiService.addCamera(token: token, payload: payload);
      _cameras = [camera, ..._cameras];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setRangeFilter({double? min, double? max}) {
    _minRange = min;
    _maxRange = max;
    notifyListeners();
  }

  void setSurveyorFilter(int? surveyorId) {
    _selectedSurveyorId = surveyorId;
    notifyListeners();
  }

  void setDateFilter({DateTime? from, DateTime? to}) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _minRange = null;
    _maxRange = null;
    _selectedSurveyorId = null;
    _fromDate = null;
    _toDate = null;
    notifyListeners();
  }
}
