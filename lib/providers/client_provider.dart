import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:metax_administrador/models/usuario_model.dart';

class ClientProvider with ChangeNotifier {
  late CollectionReference _ref;
  bool _loading = false;
  late List<Client> _clients = [];

  ClientProvider() {
    _ref = FirebaseFirestore.instance.collection('Clients');
    fetchClients();
  }

  bool get isLoading => _loading;
  List<Client> get clients => _clients;

  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  Future<void> fetchClients() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Clients')
          .where('status', whereIn: ['registrado', 'procesando'])
          .get();

      _clients = snapshot.docs
          .map((doc) => Client.fromJson(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error cargando clientes: $e');
    }
  }

  Future<int> fetchTotalClients() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Clients')
        .get();

    return snapshot.size;
  }

  Future<void> create(Client client) async {
    try {
      await _ref.doc(client.id).set(client.toJson());
      print('Usuario creado exitosamente');
    } catch (error) {
      print('Error al crear el Usuario: $error');
    }
  }

  Future<void> update(Map<String, dynamic> data, String id) async {
    try {
      await _ref.doc(id).update(data);
      print('Usuario actualizado exitosamente');
    } catch (error) {
      print('Error al actualizar el Usuario: $error');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _ref.doc(id).delete();
      print('Usuario eliminado exitosamente');
    } catch (error) {
      print('Error al eliminar el Usuario: $error');
    }
  }

  Future<void> searchClients(String query) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Clients')
          .get();

      _clients = snapshot.docs
          .map((doc) => Client.fromJson(doc.data()))
          .where((client) =>
      client.nombres.toLowerCase().contains(query.toLowerCase()) ||
          client.apellidos.toLowerCase().contains(query.toLowerCase()) ||
          client.celular.contains(query))
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error buscando clientes: $e');
    }
  }


}
