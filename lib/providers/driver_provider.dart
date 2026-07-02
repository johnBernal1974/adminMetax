import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Pages/ConductoresPage/conductores_page.dart';
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

    print(
        "🔥🔥🔥 DriverProvider CREADO"
    );

    _ref = FirebaseFirestore.instance.collection('Drivers');

    _travelHistoryRef =
        FirebaseFirestore.instance.collection('TravelHistory');

    _travelHistoryCount = 0;

    fetchDrivers();

    fetchTravelHistoryCount();
  }

  bool get isLoading => _loading;
  List<Driver> get drivers => _drivers;
  int get travelHistoryCount => _travelHistoryCount; // Getter para obtener el valor de travelHistoryCount



  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  Future<void> fetchDrivers() async {
    print(
        "🔥 fetchDrivers EJECUTADO ${DateTime.now()}"
    );
    setLoading(true);
    try {
      QuerySnapshot querySnapshot = await _ref.get();

      print("Docs en Firestore: ${querySnapshot.docs.length}");

      List<Driver> tempDrivers = [];

      int lecturasVehiculos = 0;
      for (var doc in querySnapshot.docs) {

        final data =
        doc.data() as Map<String, dynamic>;

        data["id"] = doc.id;
        print(data["vehiculoActivoId"]);

        /// 🚕 VEHÍCULO ACTIVO
        final vehiculoId =
            data["18_Placa"] ?? '';

        try {

          if (vehiculoId.isNotEmpty) {

            final vehiculoDoc =
            await FirebaseFirestore.instance

                .collection("Drivers")
                .doc(doc.id)
                .collection("vehiculos")
                .doc(vehiculoId)
                .get();

            if (vehiculoDoc.exists) {
              lecturasVehiculos++;
              final vehiculo =
              vehiculoDoc.data()!;

              data["soat_vigencia"] =

                  vehiculo["21_Vigencia_Soat"] ?? '';

              data["tecno_vigencia"] =

                  vehiculo["23_Vigencia_Tecno"] ?? '';
            }
          }

        } catch (e) {

          print(
            'ERROR VEHICULO ${doc.id}: $e',
          );
        }

        tempDrivers.add(
          Driver.fromJson(data),
        );
      }

      _drivers = tempDrivers;

      print("Drivers parseados: ${_drivers.length}");
      print(
          "🚗 Vehículos leídos General: $lecturasVehiculos"
      );

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
    print("🔥 fetchTravelHistoryCount optimizado (Solo Carros) EJECUTADO");
    try {
      // 1. Obtener el total general
      final totalQuery = await _travelHistoryRef.count().get();
      // Agregamos ?? 0 para manejar el nulo
      _travelHistoryCount = totalQuery.count ?? 0;

      // 2. Obtener conteo de carros
      final carrosQuery = await _travelHistoryRef.where('rol', isEqualTo: 'carro').count().get();
      // Agregamos ?? 0 para manejar el nulo
      travelHistoryCarroCount = carrosQuery.count ?? 0;

      // Limpiamos la variable de motos
      travelHistoryMotoCount = 0;

      notifyListeners();
    } catch (error) {
      print('Error al obtener conteos: $error');
      _travelHistoryCount = 0;
      travelHistoryCarroCount = 0;
      travelHistoryMotoCount = 0;
      notifyListeners(); // Agregado por seguridad
    }
  }

  Future<void> fetchDriversInicial() async {

    /// 1️⃣ REGISTRADOS + PROCESANDO
    final snapshotBase = await FirebaseFirestore.instance
        .collection("Drivers")
        .where("Verificacion_Status", whereIn: ["registrado", "procesando"])
        .orderBy("10_Fecha_Registro_Timestamp", descending: true)
        .get();

    /// 🔥 SOLO PENDIENTES AL INICIO
    final allDocs = [
      ...snapshotBase.docs,
    ];

    print("🚕 Registrados/Procesando: ${snapshotBase.docs.length}");

    print("🚕 Total: ${allDocs.length}");

    /// 🔥 FUNCIÓN SEGURA PARA CONVERTIR FECHAS
    DateTime parseFecha(dynamic rawFecha) {
      if (rawFecha is Timestamp) {
        return rawFecha.toDate();
      } else if (rawFecha is String) {

        return parseFechaColombia(rawFecha) ??
            DateTime(2000);
      } else {
        return DateTime(2000);
      }
    }



    drivers.clear();
    List<Driver> tempDrivers = [];

    int lecturasVehiculos = 0;
    for (var e in allDocs) {

      final data = e.data();

      data["id"] = e.id;

      final vehiculoId =
          data["18_Placa"] ?? '';

      if (vehiculoId.isNotEmpty) {

        final vehiculoDoc =
        await FirebaseFirestore.instance

            .collection("Drivers")
            .doc(e.id)
            .collection("vehiculos")
            .doc(vehiculoId)
            .get();

        if (vehiculoDoc.exists) {
          lecturasVehiculos++;
          final vehiculo =
          vehiculoDoc.data()!;

          data["soat_vigencia"] =

              vehiculo["21_Vigencia_Soat"] ?? '';

          data["tecno_vigencia"] =

              vehiculo["23_Vigencia_Tecno"] ?? '';
        }
      }

      tempDrivers.add(
        Driver.fromJson(data),
      );
    }
    print(
        "🚗 Lecturas vehículos: $lecturasVehiculos"
    );

    drivers.clear();
    drivers.addAll(tempDrivers);

    notifyListeners();
  }

  Future<void> fetchDriversActivos() async {

    final snapshotActivados = await FirebaseFirestore.instance
        .collection("Drivers")
        .where(
      "Verificacion_Status",
      isEqualTo: "activado",
    )
        .orderBy(
      "10_Fecha_Registro_Timestamp",
      descending: true,
    )
        .get();

    print(
        "🟢 Activados cargados: ${snapshotActivados.docs.length}"
    );

    drivers.clear();

    drivers.addAll(
      snapshotActivados.docs.map((e) {

        final data = e.data();

        data["id"] = e.id;

        return Driver.fromJson(data);

      }).toList(),
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
