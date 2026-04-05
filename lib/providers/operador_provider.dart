import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/operador_model.dart';

class OperadorProvider with ChangeNotifier {
  late CollectionReference _ref;

  bool _loading = false;
  late List<Operador> _operadores = [];

  // ✅ NUEVO: operador actual (para menú/guard)
  String? _rolActual;
  bool _activoActual = false;

  String? _nombreActual;
  String? _apellidosActual;

  String? get nombreActual => _nombreActual;
  String? get apellidosActual => _apellidosActual;

  OperadorProvider() {
    _ref = FirebaseFirestore.instance.collection('Operadores');
    fetchOperadorActual();
  }

  bool get isLoading => _loading;
  List<Operador> get operadores => _operadores;

  // ✅ NUEVO getters
  String? get rolActual => _rolActual;
  bool get activoActual => _activoActual;

  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  // ✅ NUEVO: SOLO el operador logueado
  Future<void> fetchOperadorActual() async {
    setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _rolActual = null;
        _activoActual = false;
        return;
      }

      final doc = await _ref.doc(user.uid).get();

      if (!doc.exists) {
        _rolActual = null;
        _activoActual = false;
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      _nombreActual = data['01_Nombres'];
      _apellidosActual = data['02_Apellidos'];
      _rolActual = (data['20_Rol'] ?? '').toString().trim();
      _activoActual = data['activo'] == true;

      print('Operador actual uid=${user.uid} rol=$_rolActual activo=$_activoActual');
    } catch (error) {
      print('Error al obtener operador actual: $error');
      _rolActual = null;
      _activoActual = false;
    } finally {
      setLoading(false);
    }
  }

  // ---------------------------
  // Lo tuyo (lo dejamos igual)
  // ---------------------------

  Future<void> fetchOperadores() async {
    setLoading(true);
    try {
      QuerySnapshot querySnapshot = await _ref.get();
      _operadores = querySnapshot.docs.map((doc) {
        print('Datos del operador: ${doc.data()}');
        return Operador.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
      print('Total de operadores obtenidos: ${_operadores.length}');
    } catch (error) {
      print('Error al obtener los operadores: $error');
      _operadores = [];
    } finally {
      setLoading(false);
    }
  }

  Future<Operador?> getById(String id) async {
    DocumentSnapshot document = await _ref.doc(id).get();
    if (document.exists) {
      Operador operador = Operador.fromJson(document.data() as Map<String, dynamic>);
      return operador;
    }
    return null;
  }

  Future<void> create(Operador operador) async {
    try {
      await _ref.doc(operador.id).set(operador.toJson());
      print('Operador creado exitosamente');
    } catch (error) {
      print('Error al crear el operador: $error');
    }
  }

  Future<void> update(Map<String, dynamic> data, String id) async {
    try {
      await _ref.doc(id).update(data);
      print('Operador actualizado exitosamente');
    } catch (error) {
      print('Error al actualizar el Operador: $error');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _ref.doc(id).delete();
      print('Operador eliminado exitosamente');
    } catch (error) {
      print('Error al eliminar el Operador: $error');
    }
  }

  Future<String?> getVerificationStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await _ref.doc(user.uid).get();
        if (snapshot.exists) {
          Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
          return userData['Verificacion_Status'];
        }
      }
      return null;
    } catch (error) {
      print('Error al obtener el estado de verificación: $error');
      return null;
    }
  }

  void clearOperadorActual() {
    _rolActual = null;
    _activoActual = false;
    _nombreActual = null;
    _apellidosActual = null;
    notifyListeners();
  }

  bool get hasRoleLoaded => _rolActual != null;
}