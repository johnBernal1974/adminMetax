import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/operador_model.dart';

class OperadorProvider with ChangeNotifier {
  late CollectionReference _ref;
  bool _loading = false;
  late List<Operador> _operadores= [];

  OperadorProvider() {
    _ref = FirebaseFirestore.instance.collection('Operadores');
    fetchOperadores();
  }

  bool get isLoading => _loading;
  List<Operador> get operadores => _operadores;

  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  Future<void> fetchOperadores() async {
    setLoading(true);
    try {
      QuerySnapshot querySnapshot = await _ref.get();
      _operadores = querySnapshot.docs.map((doc) {
        // Imprimir datos de cada documento
        print('Datos del operador: ${doc.data()}');
        return Operador.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
      // Imprimir la cantidad de usuarios obtenidos
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
    if(document.exists){
      Operador operador= Operador.fromJson(document.data() as Map<String, dynamic>);
      return operador;
    }
    else{
      return null;
    }

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
}
