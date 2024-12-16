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
    setLoading(true);
    try {
      QuerySnapshot querySnapshot = await _ref.get();
      _clients = querySnapshot.docs.map((doc) {
        return Client.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
      // Imprimir la cantidad de usuarios obtenidos
      print('Total de usuarios obtenidos: ${_clients.length}');
    } catch (error) {
      print('Error al obtener los usuarios: $error');
      _clients = [];
    } finally {
      setLoading(false);
    }
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
}
