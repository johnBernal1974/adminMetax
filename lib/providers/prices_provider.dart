import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/prices_model.dart';

class PricesProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String collectionName = 'Prices'; // Cambia esto según el nombre de tu colección


  // Obtener todos los precios
  Future<Price> getAll() async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collectionName).doc('info').get(); // Cambia 'priceDocumentId' por el ID de tu documento
      if (doc.exists) {
        return Price.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('Document does not exist');
      }
    } catch (e) {
      throw Exception('Error getting prices: $e');
    }
  }

  Future<dynamic> getPrice(String key) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('Prices').doc('info').get();
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        return data[key];
      } else {
        throw Exception("El documento no existe o no contiene datos");
      }
    } catch (error) {
      print('Error al obtener campo con key: $key. Error: $error');
      throw error;
    }
  }

  // Actualizar un precio
  Future<void> updatePrice(String key, dynamic value) async {
    try {
      await _firestore.collection('Prices').doc('info').update({key: value});
      print('Campo guardado exitosamente con key: $key y valor: $value');
    } catch (error) {
      print('Error al guardar campo con key: $key y valor: $value. Error: $error');
      throw error;
    }
  }

  // Obtener un precio por campo
  Future<dynamic> getPriceByField(String field) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collectionName).doc('info').get(); // Cambia 'priceDocumentId' por el ID de tu documento
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        return data[field];
      } else {
        throw Exception('Document does not exist');
      }
    } catch (e) {
      throw Exception('Error getting price by field: $e');
    }
  }
}

