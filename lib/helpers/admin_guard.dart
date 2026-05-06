import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'route_permissions.dart';

class AdminGuard {
  static String? _cachedUid;
  static Map<String, dynamic>? _cachedData;
  static DateTime? _cachedAt;

  static const Duration _ttl = Duration(seconds: 45);

  static Future<bool> canAccess(String routeName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _clearCache();
      return false;
    }

    if (_cachedUid != user.uid) _clearCache();

    // ✅ usa cache si está vigente
    if (_cachedData != null && _cachedAt != null) {
      final age = DateTime.now().difference(_cachedAt!);
      if (age < _ttl) {
        return _validate(routeName, _cachedData!);
      }
    }

    // ✅ consulta firestore
    final doc = await FirebaseFirestore.instance
        .collection('Operadores')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      _setCache(user.uid, {});
      return false;
    }

    final data = doc.data()!;
    _setCache(user.uid, data);

    return _validate(routeName, data);
  }

  static bool _validate(String routeName, Map<String, dynamic> data) {
    final activo = data['activo'] == true;
    final rol = (data['20_Rol'] ?? '').toString().trim();

    if (!activo) return false;

    // ✅ MASTER = ACCESO TOTAL
    if (rol == RoutePermissions.masterRole) return true;

    // ✅ valida según permisos por ruta
    return RoutePermissions.canRoleAccess(rol, routeName);
  }

  static void _setCache(String uid, Map<String, dynamic> data) {
    _cachedUid = uid;
    _cachedData = data;
    _cachedAt = DateTime.now();
  }

  static void _clearCache() {
    _cachedUid = null;
    _cachedData = null;
    _cachedAt = null;
  }
}