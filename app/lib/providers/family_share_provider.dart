import 'package:flutter/foundation.dart';
import '../models/family_member.dart';
import '../services/family_share_service.dart';

class FamilyShareProvider extends ChangeNotifier {
  final FamilyShareService _service = FamilyShareService();

  String? _userId;
  List<FamilyConnection> _myMembers = [];
  List<FamilyConnection> _sharedWithMe = [];
  bool _loading = false;
  String _error = '';

  List<FamilyConnection> get myMembers => _myMembers;
  List<FamilyConnection> get sharedWithMe => _sharedWithMe;
  bool get isLoading => _loading;
  String get error => _error;

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    if (userId == null) {
      _myMembers = [];
      _sharedWithMe = [];
      _error = '';
      notifyListeners();
      return;
    }
    loadAll();
  }

  Future<void> loadAll() async {
    if (_userId == null) return;
    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getFamilyMembers(_userId!),
        _service.getSharedWithMe(_userId!),
      ]);
      _myMembers = results[0];
      _sharedWithMe = results[1];
      _error = '';
    } catch (e) {
      _error = e.toString();
      debugPrint('[FamilyShareProvider.loadAll] $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<FamilyConnection?> joinByQr(String rawQr) async {
    if (_userId == null) return null;
    final token = _service.parseTokenFromQr(rawQr);
    if (token == null || token.isEmpty) {
      _error = 'Mã QR không hợp lệ';
      notifyListeners();
      return null;
    }

    try {
      final owner = await _service.joinByToken(
        memberUserId: _userId!,
        token: token,
      );
      await loadAll();
      return owner;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return null;
    }
  }

  Future<bool> revokeMember(String memberUserId) async {
    if (_userId == null) return false;
    try {
      await _service.revokeMember(
        ownerUserId: _userId!,
        memberUserId: memberUserId,
      );
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveShare(String ownerUserId) async {
    if (_userId == null) return false;
    try {
      await _service.leaveShare(
        memberUserId: _userId!,
        ownerUserId: ownerUserId,
      );
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  String? buildInviteQrPayload(String? token) {
    if (token == null) return null;
    return _service.buildQrPayload(token);
  }
}
