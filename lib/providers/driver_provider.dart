import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/conductor_model.dart';

class DriverProvider with ChangeNotifier {
  late CollectionReference _ref;
  late CollectionReference _travelHistoryRef;
  bool _loading = false;
  late List<Driver> _drivers = [];
  late int _travelHistoryCount;
  int travelHistoryMotoCount = 0; // Variable para contar "moto"
  int travelHistoryCarroCount = 0; // Variable para contar "carro"

  DriverProvider() {
    _ref = FirebaseFirestore.instance.collection('Drivers');
    _travelHistoryRef = FirebaseFirestore.instance.collection('TravelHistory');
    _travelHistoryCount = 0; // Inicializamos en 0
    fetchDrivers();
    fetchTravelHistoryCount(); // Llamamos al método para obtener el count inicial
  }

  bool get isLoading => _loading;
  List<Driver> get drivers => _drivers;
  int get travelHistoryCount => _travelHistoryCount; // Getter para obtener el valor de travelHistoryCount

  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  Future<void> fetchDrivers() async {
    setLoading(true);
    try {
      QuerySnapshot querySnapshot = await _ref.get();
      for (var doc in querySnapshot.docs) {
        //print('Datos crudos del documento: ${doc.data()}'); // Imprime los datos crudos
      }
      _drivers = querySnapshot.docs.map((doc) {
        return Driver.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
      print('Total de conductores obtenidos: ${_drivers.length}');
      notifyListeners();
    } catch (error) {
      print('Error al obtener los conductores: $error');
      _drivers = [];
    } finally {
      setLoading(false);
    }
  }

  List<Driver> getDriversByRole(String role) {
    return _drivers.where((driver) => driver.rol == role).toList();
  }

  // Función para obtener conductores por rol y estado de trabajo
  List<Driver> getDriversByRoleAndWorkingStatus(String role, bool isWorking) {
    return _drivers
        .where((driver) => driver.rol == role && driver.the00_is_working == isWorking)
        .toList();
  }

  List<Driver> getDriversByRoleAndActiveStatus(String role, bool isActive) {
    return _drivers
        .where((driver) => driver.rol == role && driver.the00_is_active == isActive)
        .toList();
  }

  // List<Driver> getDriversByIsWorking(bool isWorking) {
  //   return _drivers.where((driver) => driver.the00_is_working == true).toList();
  // }
  //
  // List<Driver> getDriversByIsActive(bool isActive) {
  //   return _drivers.where((driver) => driver.the00_is_active == true).toList();
  // }

  Future<void> create(Driver driver) async {
    try {
      await _ref.doc(driver.id).set(driver.toJson());
      print('Conductor creado exitosamente');
    } catch (error) {
      print('Error al crear el conductor: $error');
    }
  }

  Future<void> update(Map<String, dynamic> data, String id) async {
    try {
      await _ref.doc(id).update(data);
      print('Conductor actualizado exitosamente');
    } catch (error) {
      print('Error al actualizar el conductor: $error');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _ref.doc(id).delete();
      print('Conductor eliminado exitosamente');
    } catch (error) {
      print('Error al eliminar el conductor: $error');
    }
  }

  // Nuevo método para obtener el número de documentos en la colección "TravelHistory"
  Future<int> getTravelHistoryCount() async {
    try {
      QuerySnapshot querySnapshot = await _travelHistoryRef.get();
      int count = querySnapshot.size;
      return count;
    } catch (error) {
      print('Error al obtener el número de documentos en TravelHistory: $error');
      return 0;
    }
  }


  Future<void> fetchTravelHistoryCount() async {
    try {
      QuerySnapshot querySnapshot = await _travelHistoryRef.get();
      _travelHistoryCount = querySnapshot.size;

      // Filtrar y contar los documentos con rol "moto"
      travelHistoryMotoCount = querySnapshot.docs
          .where((doc) => doc.get('rol') == 'moto')
          .length;

      // Filtrar y contar los documentos con rol "carro"
      travelHistoryCarroCount = querySnapshot.docs
          .where((doc) => doc.get('rol') == 'carro')
          .length;
      notifyListeners(); // Notificamos a los oyentes que el valor ha cambiado
    } catch (error) {
      print('Error al obtener el número de documentos en TravelHistory: $error');
      _travelHistoryCount = 0;
      travelHistoryMotoCount = 0;
      travelHistoryCarroCount = 0;
    }
  }
}
