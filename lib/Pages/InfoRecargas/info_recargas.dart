import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/main_layout.dart';
class RecargaPage extends StatefulWidget {
  @override
  _RecargaPageState createState() => _RecargaPageState();
}

class _RecargaPageState extends State<RecargaPage> {
  int totalRecarga = 0;
  int cantidadAutomovil = 0;
  int cantidadMotocicleta = 0;
  int totalRecargaAutomovil = 0;
  int totalRecargaMotocicleta = 0;
  String selectedInterval = 'Hoy'; // Intervalo inicial
  String displayDate = ''; // Texto del día/rango seleccionado
  final NumberFormat currencyFormat = NumberFormat.currency(symbol: "\$", decimalDigits: 0);
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final DateFormat dayFormat = DateFormat('EEEE, dd MMMM yyyy', 'es_ES');
  List<QueryDocumentSnapshot> filteredDocs = [];


  String? selectedMonth; // Mes seleccionado en el segundo dropdown
  bool showMonthDropdown = false; // Controla si se muestra el dropdown de meses
  bool showYearDropdown = false; // Controla si se muestra el dropdown de meses
  String? selectedYear;
  List<String> yearsList = List.generate(10, (index) => (DateTime.now().year - index).toString()); // Lista de los últimos 10 años

  // Aquí puedes definir los documentos que serán filtrados según la placa
  List<String> allDocuments = ['Documento 1', 'Documento 2', 'Documento 3'];
  List<String> filteredDocuments = [];
  TextEditingController plateController = TextEditingController();
  List<String> filteredDocumentsList = [];


  @override
  void initState() {
    super.initState();
    _updateDisplayDate(); // Inicializar el texto del día/rango seleccionado
    filteredDocuments = allDocuments;
    _calcularTotales();
  }



  Future<void> _updateDisplayDate() async {
    DateTime now = DateTime.now();
    DateTime startDate, endDate;

    // Verifica si la selección actual es 'Placa'
    if (selectedInterval == 'Placa') {
      String plate = plateController.text.trim(); // Obtén la placa escrita por el usuario
      if (plate.isNotEmpty) {
        await _filtrarPorPlaca(plate); // Filtra los documentos por placa
        displayDate = 'Buscando documentos para la placa: $plate';
      } else {
        filteredDocumentsList.clear(); // Limpia los resultados si no hay placa
        displayDate = 'Por favor ingrese una placa válida.';
      }
      setState(() {});
      return; // Salimos de la función para no continuar con el resto de la lógica
    }

    // Si no es 'Placa', continúa con la lógica de cálculo por fechas
    switch (selectedInterval) {
      case 'Hoy':
        startDate = DateTime(now.year, now.month, now.day);
        displayDate = dayFormat.format(startDate); // Usa dayFormat aquí
        break;
      case 'Ayer':
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 1));
        displayDate = dayFormat.format(startDate); // Usa dayFormat aquí
        break;
      case 'Esta semana':
        startDate = now.subtract(Duration(days: now.weekday - 1)); // Primer día de la semana actual
        endDate = now.add(Duration(days: 7 - now.weekday)); // Último día de la semana actual
        displayDate = '${dayFormat.format(startDate)} - ${dayFormat.format(endDate)}'; // Usa dayFormat
        break;
      case 'Semana anterior':
        startDate = now.subtract(Duration(days: now.weekday + 6)); // Primer día de la semana anterior
        endDate = now.subtract(Duration(days: now.weekday)); // Último día de la semana anterior
        displayDate = '${dayFormat.format(startDate)} - ${dayFormat.format(endDate)}'; // Usa dayFormat
        break;
      case 'Mes':
        startDate = DateTime(now.year, now.month, 1); // Primer día del mes actual
        endDate = DateTime(now.year, now.month + 1, 1).subtract(Duration(days: 1)); // Último día del mes actual
        displayDate = '${dayFormat.format(startDate)} - ${dayFormat.format(endDate)}'; // Usa dayFormat
        break;
      case 'Año':
        startDate = DateTime(now.year, 1, 1); // Primer día del año actual
        endDate = DateTime(now.year + 1, 1, 1).subtract(Duration(days: 1)); // Último día del año actual
        displayDate = '${dayFormat.format(startDate)} - ${dayFormat.format(endDate)}'; // Usa dayFormat
        break;
      default:
        displayDate = '';
    }
  }



  Future<void> _calcularTotales() async {
    DateTime now = DateTime.now();
    DateTime startDate, endDate;

    // Verifica si la selección actual es "Placa" y maneja el filtro correspondiente
    if (selectedInterval == 'Placa') {
      String plate = plateController.text.trim(); // Obtén la placa escrita por el usuario
      if (plate.isNotEmpty) {
        // Llamada a la función de filtrado por placa
        await _filtrarPorPlaca(plate);
        return; // Salimos de la función ya que la búsqueda se maneja por placa
      } else {
        // Si la placa no está ingresada, puedes mostrar un error o manejar el caso
        print('Por favor ingrese una placa válida.');
        return;
      }
    }

    switch (selectedInterval) {
      case 'Hoy':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(Duration(days: 1));
        break;
      case 'Ayer':
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 1));
        endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Semana':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = now.add(Duration(days: 7 - now.weekday));
        break;
      case 'Semana anterior':
        startDate = DateTime(now.year, now.month, now.day - (now.weekday + 6)).toUtc();
        endDate = DateTime(now.year, now.month, now.day - now.weekday, 23, 59, 59).toUtc();
        break;
      case 'Mes':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1).subtract(Duration(days: 1));
        break;
      case 'Año':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1).subtract(Duration(days: 1));
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(Duration(days: 1));
    }

    startDate = startDate.toUtc();
    endDate = endDate.toUtc();

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recargas')
        .where('fecha_hora', isGreaterThanOrEqualTo: startDate)
        .where('fecha_hora', isLessThan: endDate)
        .get();

    int total = 0, autos = 0, motos = 0, totalAutos = 0, totalMotos = 0;

    for (var doc in snapshot.docs) {
      int recarga = doc['2nueva_recarga'] ?? 0;
      String tipoVehiculo = doc['tipoVehiculo'] ?? '';

      total += recarga;

      if (tipoVehiculo == 'Automovil') {
        autos++;
        totalAutos += recarga;
      } else if (tipoVehiculo == 'Motocicleta') {
        motos++;
        totalMotos += recarga;
      }
    }

    setState(() {
      totalRecarga = total;
      cantidadAutomovil = autos;
      cantidadMotocicleta = motos;
      totalRecargaAutomovil = totalAutos;
      totalRecargaMotocicleta = totalMotos;
      filteredDocs = snapshot.docs;
    });
  }

  List<String> meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  void _onIntervalChange(String? newInterval) {
    setState(() {
      selectedInterval = newInterval!;
      _updateDisplayDate(); // Actualizar el texto al cambiar el intervalo
    });
    _calcularTotales(); // Recalcular totales al cambiar el intervalo
  }

  Future<void> _filtrarPorPlaca(String placaSeleccionada) async {
    if (placaSeleccionada.isEmpty) {
      setState(() {
        filteredDocs = []; // Limpia los resultados si no se ingresa una placa
        totalRecarga = 0;
        cantidadAutomovil = 0;
        cantidadMotocicleta = 0;
        totalRecargaAutomovil = 0;
        totalRecargaMotocicleta = 0;
      });
      return;
    }

    try {
      // Obtiene todos los documentos de la colección
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('recargas') // Cambia a tu colección
          .get();

      // Filtra los documentos en el cliente ignorando mayúsculas y minúsculas
      List<QueryDocumentSnapshot> filteredDocsList = snapshot.docs.where((doc) {
        String placa = (doc['placa'] ?? '').toString(); // Campo de placa
        return placa.toLowerCase().contains(placaSeleccionada.toLowerCase());
      }).toList();

      // Procesar los documentos filtrados
      int total = 0;
      int autos = 0;
      int motos = 0;
      int totalAutos = 0;
      int totalMotos = 0;

      for (var doc in filteredDocsList) {
        int recarga = doc['2nueva_recarga'] ?? 0;
        String tipoVehiculo = doc['tipoVehiculo'] ?? '';

        total += recarga;

        if (tipoVehiculo == 'Automovil') {
          autos++;
          totalAutos += recarga;
        } else if (tipoVehiculo == 'Motocicleta') {
          motos++;
          totalMotos += recarga;
        }
      }

      setState(() {
        totalRecarga = total;
        cantidadAutomovil = autos;
        cantidadMotocicleta = motos;
        totalRecargaAutomovil = totalAutos;
        totalRecargaMotocicleta = totalMotos;
        filteredDocs = filteredDocsList; // Actualiza los documentos filtrados
      });
    } catch (e) {
      print("Error al filtrar por placa: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    // Usamos MediaQuery para verificar el tamaño de la pantalla
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return MainLayout(
      pageTitle: 'Historial de Recargas',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                if (showMonthDropdown) ...[
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedMonth,
                    hint: const Text('Selecciona un mes'),
                    items: meses.map((String mes) {
                      return DropdownMenuItem<String>(
                        value: mes,
                        child: Text(mes),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedMonth = value;
                        if (selectedMonth != null) {
                          _filtrarPorMes(selectedMonth!);
                        }
                      });
                    },
                  ),
                ],
                if (showYearDropdown) ...[
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedYear,
                    hint: const Text('Selecciona un año'),
                    items: yearsList.map((String mes) {
                      return DropdownMenuItem<String>(
                        value: mes,
                        child: Text(mes),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedYear = value;
                        if (selectedYear != null) {
                          _filterDocumentsByYear();
                        }
                      });
                    },
                  ),
                ],

                if (selectedInterval == 'Placa') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: plateController,
                      decoration: const InputDecoration(
                        labelText: 'Ingrese la placa',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _filtrarPorPlaca(value); // Filtrar documentos según la placa
                      },
                    ),
                  ),
                ],

                Wrap(
                  spacing: 8,  // Espacio entre los elementos
                  runSpacing: 4,  // Espacio entre las líneas
                  children: [
                    DropdownButton<String>(
                      value: selectedInterval,
                      onChanged: (String? value) {
                        setState(() {
                          selectedInterval = value!;
                          if (value == 'Mes') {
                            showMonthDropdown = true;
                            showYearDropdown = false;
                            selectedMonth = null;
                            selectedYear = null;
                          } else if (value == 'Año') {
                            showYearDropdown = true;
                            showMonthDropdown = false;
                            selectedMonth = null;
                            selectedYear = null;
                            _filterDocumentsByYear();
                          }
                          else if (value == 'Placa') {
                            // Si se selecciona 'Placa', mostrar el campo de búsqueda
                            showMonthDropdown = false;
                            showYearDropdown = false;
                          }else {
                            showMonthDropdown = false;
                            showYearDropdown = false;
                            selectedMonth = null;
                            selectedYear = null;
                            _calcularTotales();
                          }
                        });
                      },
                      items: <String>['Hoy', 'Ayer', 'Esta semana', 'Semana anterior', 'Mes', 'Año', 'Placa']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    Text(
                      _getIntervalDescription(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor Total general de recargas:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currencyFormat.format(totalRecarga),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recargas de Automóviles: ${cantidadAutomovil.toString()}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Valor Total recargas: ${currencyFormat.format(totalRecargaAutomovil)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recargas de Motocicletas: ${cantidadMotocicleta.toString()}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Valor Total recargas: ${currencyFormat.format(totalRecargaMotocicleta)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),

          // Mostrar la tabla si no estamos en móvil
          if (!isMobile && filteredDocs.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Placa')),
                    DataColumn(label: Text('Tipo de Vehículo')),
                    DataColumn(label: Text('Saldo Anterior')),
                    DataColumn(label: Text('Nueva Recarga')),
                    DataColumn(label: Text('Saldo Total')),
                    DataColumn(label: Text('Fecha y Hora')),
                    DataColumn(label: Text('Operador')),
                  ],
                  rows: (filteredDocs
                    ..sort((a, b) {
                      Timestamp timestampA = a['fecha_hora'];
                      Timestamp timestampB = b['fecha_hora'];
                      return timestampB.compareTo(timestampA);
                    })
                  ).map((doc) {
                    return DataRow(cells: [
                      DataCell(Text(doc['placa'])),
                      DataCell(Text(doc['tipoVehiculo'])),
                      DataCell(Text(currencyFormat.format(doc['1saldo_anterior']))),
                      DataCell(Text(currencyFormat.format(doc['2nueva_recarga']), style: const TextStyle(fontWeight: FontWeight.w700))),
                      DataCell(Text(currencyFormat.format(doc['3saldo_total']))),
                      DataCell(Text(dateFormat.format((doc['fecha_hora'] as Timestamp).toDate()))),
                      DataCell(Text(doc['operador'])),
                    ]);
                  }).toList(),
                ),
              ),
            ),

          // Mostrar tarjetas si estamos en móvil
          if (isMobile && filteredDocs.isNotEmpty)
            Expanded(
              child: ListView(
                children: filteredDocs.map((doc) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Placa
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Placa:', style: TextStyle(fontSize: 10, height: 1)),
                              Text(
                                '${doc['placa']}',
                                style: const TextStyle(fontSize: 10, height: 1), // Cambié el tamaño aquí también
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Tipo de Vehículo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tipo de Vehículo:', style: TextStyle(fontSize: 10, height: 1)), // Tamaño de fuente cambiado aquí
                              Text('${doc['tipoVehiculo']}', style: const TextStyle(fontSize: 10, height: 1)), // También se cambió el tamaño aquí
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Saldo Anterior
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Saldo Anterior:', style: TextStyle(fontSize: 10, height: 1)), // Tamaño de fuente cambiado aquí
                              Text(currencyFormat.format(doc['1saldo_anterior']), style: const TextStyle(fontSize: 10, height: 1)), // Aquí también
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Nueva Recarga
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Nueva Recarga:', style: TextStyle(fontSize: 10, height: 1)), // Tamaño de fuente cambiado aquí
                              Text(
                                currencyFormat.format(doc['2nueva_recarga']),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, height: 1), // Tamaño cambiado y peso de fuente también
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Saldo Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Saldo Total:', style: TextStyle(fontSize: 10, height: 1)), // Tamaño de fuente cambiado aquí
                              Text(currencyFormat.format(doc['3saldo_total']), style: const TextStyle(fontSize: 10, height: 1)), // Tamaño de fuente cambiado aquí
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Fecha y Hora
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Fecha y Hora:', style: TextStyle(fontSize: 10, height: 1)), // Tamaño de fuente cambiado aquí
                              Text(
                                dateFormat.format((doc['fecha_hora'] as Timestamp).toDate()),
                                style: const TextStyle(fontSize: 10, height: 1), // Tamaño de fuente cambiado aquí
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Operador
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Operador:', style: TextStyle(fontSize: 10)), // Tamaño de fuente cambiado aquí
                              Text('${doc['operador']}', style: const TextStyle(fontSize: 10, height: 1)), // Tamaño de fuente cambiado aquí
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),

                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 50),

          if (filteredDocs.isEmpty)
            const Center(child: Text('No hay recargas para el intervalo seleccionado')),

        ],
      ),
    );
  }


  Future<void> _filtrarPorMes(String mesSeleccionado) async {
    DateTime now = DateTime.now();
    int monthIndex = meses.indexOf(mesSeleccionado) + 1;

    // Obtener el rango del mes seleccionado
    DateTime startDate = DateTime(now.year, monthIndex, 1);
    DateTime endDate = DateTime(now.year, monthIndex + 1, 1).subtract(Duration(days: 1));

    // Convertir a UTC para la consulta
    startDate = startDate.toUtc();
    endDate = endDate.toUtc();

    // Consultar en Firestore
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recargas')
        .where('fecha_hora', isGreaterThanOrEqualTo: startDate)
        .where('fecha_hora', isLessThanOrEqualTo: endDate)
        .get();

    // Procesar resultados
    int total = 0;
    int autos = 0;
    int motos = 0;
    int totalAutos = 0;
    int totalMotos = 0;

    for (var doc in snapshot.docs) {
      int recarga = doc['2nueva_recarga'] ?? 0;
      String tipoVehiculo = doc['tipoVehiculo'] ?? '';

      total += recarga;

      if (tipoVehiculo == 'Automovil') {
        autos++;
        totalAutos += recarga;
      } else if (tipoVehiculo == 'Motocicleta') {
        motos++;
        totalMotos += recarga;
      }
    }

    setState(() {
      totalRecarga = total;
      cantidadAutomovil = autos;
      cantidadMotocicleta = motos;
      totalRecargaAutomovil = totalAutos;
      totalRecargaMotocicleta = totalMotos;
      filteredDocs = snapshot.docs;
    });
  }

  Future<void> _filterDocumentsByYear() async {
    DateTime now = DateTime.now();
    DateTime startDate, endDate;

    // Si se seleccionó un año, filtrar los documentos de ese año
    if (selectedYear != null) {
      startDate = DateTime(int.parse(selectedYear!), 1, 1); // Primer día del año seleccionado
      endDate = DateTime(int.parse(selectedYear!) + 1, 1, 1); // Primer día del siguiente año

      // Convertir startDate y endDate a UTC
      startDate = startDate.toUtc(); // Aseguramos que esté en UTC
      endDate = endDate.toUtc(); // Aseguramos que esté en UTC

      // Realizar la consulta en Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('recargas')
          .where('fecha_hora', isGreaterThanOrEqualTo: startDate)
          .where('fecha_hora', isLessThan: endDate)
          .get();

      // Verifica si se recuperaron documentos
      print('Total de documentos recuperados para el año $selectedYear: ${snapshot.docs.length}');

      // Inicializamos las variables para el cálculo de totales
      int total = 0;
      int autos = 0;
      int motos = 0;
      int totalAutos = 0;
      int totalMotos = 0;

      // Procesar los documentos
      for (var doc in snapshot.docs) {
        int recarga = doc['2nueva_recarga'] ?? 0;
        String tipoVehiculo = doc['tipoVehiculo'] ?? '';

        total += recarga;

        // Verificamos el tipo de vehículo y actualizamos los totales correspondientes
        if (tipoVehiculo == 'Automovil') {
          autos++;
          totalAutos += recarga;
        } else if (tipoVehiculo == 'Motocicleta') {
          motos++;
          totalMotos += recarga;
        }
      }

      // Actualizamos el estado para mostrar los resultados en la interfaz
      setState(() {
        totalRecarga = total;
        cantidadAutomovil = autos;
        cantidadMotocicleta = motos;
        totalRecargaAutomovil = totalAutos;
        totalRecargaMotocicleta = totalMotos;
        filteredDocs = snapshot.docs;
      });
    }
  }

  String _getIntervalDescription() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d MMMM', 'es_ES'); // Formato para día, mes y año en español.

    switch (selectedInterval) {
      case 'Hoy':
        return 'Hoy: ${formatter.format(now)}';
      case 'Ayer':
        return 'Ayer: ${formatter.format(now.subtract(Duration(days: 1)))}';
      case 'Esta semana':
        final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final lastDayOfWeek = now.add(Duration(days: 7 - now.weekday));
        return 'Semana Actual: ${DateFormat('d MMM', 'es_ES').format(firstDayOfWeek)} - ${DateFormat('d MMM', 'es_ES').format(lastDayOfWeek)}';
      case 'Semana anterior':
        final firstDayOfPreviousWeek = now.subtract(Duration(days: now.weekday + 6)); // Hace 7 días más que el inicio de esta semana
        final lastDayOfPreviousWeek = now.subtract(Duration(days: now.weekday));
        return 'Semana Anterior: ${DateFormat('d MMM', 'es_ES').format(firstDayOfPreviousWeek)} - ${DateFormat('d MMM', 'es_ES').format(lastDayOfPreviousWeek)}';
      case 'Mes':
        return 'Mes Actual: ${DateFormat('MMMM yyyy', 'es_ES').format(now)}';
      case 'Año':
        return 'Año Actual: ${now.year}';
      default:
        return '';
    }
  }

}
