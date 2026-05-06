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

      print("Docs en Firestore: ${querySnapshot.docs.length}");

      _drivers = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        data["id"] = doc.id; // 🔥 SOLUCIÓN

        return Driver.fromJson(data);
      }).toList();

      print("Drivers parseados: ${_drivers.length}");

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
    return _drivers.where((driver) =>
    driver.rol == role &&
        driver.the00_is_working == isWorking
    ).toList();
  }

  List<Driver> getDriversByRoleAndActiveStatus(String role, bool isActive) {
    return _drivers.where((driver) =>
    driver.rol == role &&
        driver.the00_is_active == isActive
    ).toList();
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

  Future<void> fetchDriversInicial() async {

    /// 1️⃣ REGISTRADOS + PROCESANDO
    final snapshotBase = await FirebaseFirestore.instance
        .collection("Drivers")
        .where("Verificacion_Status", whereIn: ["registrado", "procesando"])
        .orderBy("10_Fecha_Registro_Timestamp", descending: true)
        .get();

    /// 2️⃣ ACTIVADOS
    final snapshotActivados = await FirebaseFirestore.instance
        .collection("Drivers")
        .where("Verificacion_Status", isEqualTo: "activado")
        .orderBy("10_Fecha_Registro_Timestamp", descending: true)
        .get();

    // /// 🔥 FILTRAR SOLO LOS QUE TIENEN CORREGIDA
    // final activadosConCorregida = snapshotActivados.docs.where((doc) {
    //   final data = doc.data();
    //
    //   return data["29_Foto_perfil"] == "corregida" ||
    //       data["25_Cedula_Delantera_foto"] == "corregida" ||
    //       data["26_Cedula_Trasera_foto"] == "corregida";
    // }).toList();

    /// 🔥 UNIR TODO
    final allDocs = [
      ...snapshotBase.docs,
      ...snapshotActivados.docs, // 🔥 TODOS los activados
    ];

    /// 🔥 FUNCIÓN SEGURA PARA CONVERTIR FECHAS
    DateTime parseFecha(dynamic rawFecha) {
      if (rawFecha is Timestamp) {
        return rawFecha.toDate();
      } else if (rawFecha is String) {
        return DateTime.tryParse(rawFecha) ?? DateTime(2000);
      } else {
        return DateTime(2000);
      }
    }

    /// 🔥 ORDEN FINAL (YA NO ROMPE NUNCA)
    allDocs.sort((a, b) {
      final fechaA = parseFecha(a["10_Fecha_Registro_Timestamp"]);
      final fechaB = parseFecha(b["10_Fecha_Registro_Timestamp"]);

      return fechaB.compareTo(fechaA);
    });

    drivers.clear();
    drivers.addAll(
      allDocs.map((e) => Driver.fromJson(e.data())).toList(),
    );

    notifyListeners();
  }

  Future<void> buscarDriver(String query) async {
    print("🔍 BUSCANDO: $query");

    if (query.trim().isEmpty) {
      await fetchDriversInicial();
      return;
    }

    final q = query.trim().toLowerCase();

    /// 🔥 1. TRAER TODOS LOS DRIVERS (ya los tienes en memoria)
    final allDrivers = List<Driver>.from(drivers);

    /// 🔥 2. FILTRO LOCAL (NOMBRE, APELLIDO, CELULAR, DOC)
    final filtrados = allDrivers.where((driver) {
      final nombre = (driver.the01Nombres ?? "").toLowerCase();
      final apellido = (driver.the02Apellidos ?? "").toLowerCase();
      final celular = (driver.the07Celular ?? "").toLowerCase();
      final documento = (driver.the03NumeroDocumento ?? "").toLowerCase();

      return nombre.contains(q) ||
          apellido.contains(q) ||
          celular.contains(q) ||
          documento.contains(q);
    }).toList();

    /// 🔥 3. SI ENCUENTRA ALGO → DEVUELVE
    if (filtrados.isNotEmpty) {
      drivers.clear();
      drivers.addAll(filtrados);
      notifyListeners();
      return;
    }

    /// 🔥 4. SI NO → BUSCAR POR PLACA (Firestore)
    final queryFormatted = query.trim().toUpperCase();

    final vehiculosSnapshot = await FirebaseFirestore.instance
        .collectionGroup("vehiculos")
        .where("18_Placa", isEqualTo: queryFormatted)
        .get();

    List<String> driverIds = vehiculosSnapshot.docs
        .map((doc) => doc["driverId"] as String)
        .toSet()
        .toList();

    if (driverIds.isNotEmpty) {
      final driversSnapshot = await FirebaseFirestore.instance
          .collection("Drivers")
          .where(FieldPath.documentId, whereIn: driverIds)
          .get();

      drivers.clear();
      drivers.addAll(
        driversSnapshot.docs.map((e) => Driver.fromJson(e.data())).toList(),
      );
    } else {
      await fetchDriversInicial();
    }

    notifyListeners();
  }

}
