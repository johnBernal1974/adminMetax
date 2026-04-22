import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../common/main_layout.dart';
import '../../src/color.dart';

class AdminTransaccionesPage extends StatefulWidget {
  const AdminTransaccionesPage({super.key});

  @override
  _AdminTransaccionesPageState createState() => _AdminTransaccionesPageState();
}

class _AdminTransaccionesPageState extends State<AdminTransaccionesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? fechaInicio;
  DateTime? fechaFin;

  final TextEditingController anioController = TextEditingController();
  final TextEditingController mesController = TextEditingController();
  final TextEditingController diaController = TextEditingController();

  String filtroRapidoActivo = "";


  Widget build(BuildContext context) {

    return MainLayout(
      pageTitle: "Transacciones",
      content: Center(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),

            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [

                    /// 🔵 HOY
                    ElevatedButton(
                      style: estiloBoton("hoy"),
                      onPressed: () {
                        final now = DateTime.now();

                        setState(() {
                          filtroRapidoActivo = "hoy";

                          fechaInicio = DateTime(now.year, now.month, now.day);
                          fechaFin = DateTime(now.year, now.month, now.day, 23, 59, 59);

                          /// 🔥 limpiar inputs
                          anioController.clear();
                          mesController.clear();
                          diaController.clear();
                        });
                      },
                      child: const Text("Hoy"),
                    ),

                    /// 🟣 MES
                    ElevatedButton(
                      style: estiloBoton("mes"),
                      onPressed: () {
                        final now = DateTime.now();

                        setState(() {
                          filtroRapidoActivo = "mes";

                          fechaInicio = DateTime(now.year, now.month, 1);
                          fechaFin = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

                          anioController.clear();
                          mesController.clear();
                          diaController.clear();
                        });
                      },
                      child: const Text("Este mes"),
                    ),

                    /// 🟢 AÑO
                    ElevatedButton(
                      style: estiloBoton("anio"),
                      onPressed: () {
                        final now = DateTime.now();

                        setState(() {
                          filtroRapidoActivo = "anio";

                          fechaInicio = DateTime(now.year, 1, 1);
                          fechaFin = DateTime(now.year, 12, 31, 23, 59, 59);

                          anioController.clear();
                          mesController.clear();
                          diaController.clear();
                        });
                      },
                      child: const Text("Este año"),
                    ),

                    /// ⚪ TODOS
                    ElevatedButton(
                      style: estiloBoton("todos"),
                      onPressed: () {
                        setState(() {
                          filtroRapidoActivo = "todos";

                          fechaInicio = null;
                          fechaFin = null;

                          anioController.clear();
                          mesController.clear();
                          diaController.clear();
                        });
                      },
                      child: const Text("Todos"),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [

                    /// 📅 AÑO
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: anioController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Año",
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                    /// 📅 MES
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: mesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Mes",
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                    /// 📅 DÍA
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: diaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Día",
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                    /// 🔍 BUSCAR
                    ElevatedButton(
                      onPressed: () {
                        final anio = int.tryParse(anioController.text);
                        final mes = int.tryParse(mesController.text);
                        final dia = int.tryParse(diaController.text);

                        if (anio != null && mes == null && dia == null) {
                          fechaInicio = DateTime(anio, 1, 1);
                          fechaFin = DateTime(anio, 12, 31, 23, 59, 59);
                        } else if (anio != null && mes != null && dia == null) {
                          fechaInicio = DateTime(anio, mes, 1);
                          fechaFin = DateTime(anio, mes + 1, 0, 23, 59, 59);
                        } else if (anio != null && mes != null && dia != null) {
                          fechaInicio = DateTime(anio, mes, dia);
                          fechaFin = DateTime(anio, mes, dia, 23, 59, 59);
                        }

                        setState(() {
                          /// 🔥 DESACTIVA BOTONES
                          filtroRapidoActivo = "";
                        });
                      },
                      child: const Text("Buscar"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection("recargas")
                        .orderBy("createdAt", descending: true)
                        .where("createdAt", isGreaterThanOrEqualTo: fechaInicio ?? DateTime(2000))
                        .where("createdAt", isLessThanOrEqualTo: fechaFin ?? DateTime.now())
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No hay transacciones registradas."));
                      }
                  
                      List<QueryDocumentSnapshot> transacciones = snapshot.data!.docs;
                  
                      // Agrupar por semana
                      Map<String, List<QueryDocumentSnapshot>> transaccionesPorSemana = {};
                      Map<String, int> totalPorSemana = {};
                      int totalGlobal = 0;
                  
                      for (var transaction in transacciones) {
                        var fecha = (transaction["createdAt"] as Timestamp).toDate();
                  
                        // 🔥 Obtener el inicio y fin de la semana (lunes - domingo)
                        DateTime inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1)); // Lunes
                        DateTime finSemana = inicioSemana.add(const Duration(days: 6)); // Domingo
                  
                        // 🔥 Formatear para mostrar "Semana entre el 10 y el 16 de marzo de 2025"
                        String semana = "Semana entre el ${DateFormat("d", 'es_CO').format(inicioSemana)} "
                            "y el ${DateFormat("d 'de' MMMM 'de' yyyy", 'es_CO').format(finSemana)}";
                  
                        transaccionesPorSemana.putIfAbsent(semana, () => []);
                        transaccionesPorSemana[semana]!.add(transaction);
                  
                        // Solo sumar las transacciones aprobadas al total semanal y global
                        if (transaction["status"] == "APPROVED") {
                          totalPorSemana[semana] = (totalPorSemana[semana] ?? 0) + (transaction["amount"] as num).toInt();
                          totalGlobal += (transaction["amount"] as num).toInt();
                        }
                      }
                  
                      // Detectar si es móvil o PC
                      bool esMovil = MediaQuery.of(context).size.width < 800;
                  
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: gris, width: 3)
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Valor Total de Transacciones (Aprobadas)",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                Text(
                                  "\$${NumberFormat("#,###", "es_CO").format(totalGlobal)}",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                  
                          const SizedBox(height: 20),
                  
                          esMovil
                              ? _buildMobileView(transaccionesPorSemana, totalPorSemana)
                              : _buildDesktopView(transaccionesPorSemana, totalPorSemana),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle estiloBoton(String tipo) {
    final isActive = filtroRapidoActivo == tipo;

    return ElevatedButton.styleFrom(
      backgroundColor: isActive ? Colors.deepPurple : Colors.grey[300],
      foregroundColor: isActive ? Colors.white : Colors.black,
      elevation: isActive ? 6 : 1,
      padding: EdgeInsets.symmetric(
        horizontal: isActive ? 18 : 14,
        vertical: isActive ? 14 : 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  /// **🔹 Construye la Vista en Móvil (Tarjetas)**
  Widget _buildMobileView(Map<String, List<QueryDocumentSnapshot>> transaccionesPorSemana, Map<String, int> totalPorSemana) {
    return Expanded(
      child: ListView(
        children: transaccionesPorSemana.entries.map((entry) {
          String semana = entry.key;
          List<QueryDocumentSnapshot> transacciones = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana] ?? 0)}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 8),
              ...transacciones.map((transaction) => _buildTransactionCard(transaction)).toList(),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// **🔹 Construye la Vista en PC (Tabla)**
  Widget _buildDesktopView(Map<String, List<QueryDocumentSnapshot>> transaccionesPorSemana, Map<String, int> totalPorSemana) {
    return Expanded(
      child: ListView(
        children: transaccionesPorSemana.entries.map((entry) {
          String semana = entry.key;
          List<QueryDocumentSnapshot> transacciones = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana] ?? 0)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                  columns: const [
                    DataColumn(label: Text("Fecha", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Usuario", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Saldo Anterior", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Monto", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Saldo Final", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Método Pago", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Referencia", style: TextStyle(fontSize: 12))),
                  ],
                  rows: transacciones.map((transaction) {
                    var fecha = (transaction["createdAt"] as Timestamp).toDate();
                    var formattedDate = DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es_CO').format(fecha);
                    var amount = (transaction["amount"] as num).toDouble();
                    var estado = transaction["status"];
                    var paymentMethod = transaction["paymentMethod"] ?? "Desconocido";
                    var userId = transaction["userId"];
                    var transactionId = transaction["transactionId"];
                    var saldoAnterior = (transaction["saldo_anterior"] as num).toDouble();
                    var saldoFinal = estado == "APPROVED" ? saldoAnterior + amount : saldoAnterior;
                    var formattedAmount = "\$${NumberFormat("#,###", "es_CO").format(amount)}";

                    return DataRow(cells: [
                      DataCell(Text(formattedDate, style: const TextStyle(fontSize: 10))),

                      DataCell(FutureBuilder<String>(
                        future: _getUserName(userId),
                        builder: (context, snapshot) {
                          return Text(snapshot.data ?? "Cargando...", style: const TextStyle(fontSize: 10));
                        },
                      )),

                      DataCell(Text("\$${NumberFormat("#,###", "es_CO").format(saldoAnterior)}",
                          style: const TextStyle(fontSize: 11))),

                      DataCell(
                        estado == "DECLINED"
                            ? Text(formattedAmount,
                            style: const TextStyle(color: Colors.red, fontSize: 11, decoration: TextDecoration.lineThrough))
                            : Text(formattedAmount,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),

                      DataCell(Text("\$${NumberFormat("#,###", "es_CO").format(saldoFinal)}",
                          style: const TextStyle(fontSize: 11))),

                      DataCell(Text(paymentMethod, style: const TextStyle(fontSize: 10))),

                      /// 🔥 REFERENCIA + ESTADO
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(transactionId, style: const TextStyle(fontSize: 11)),

                            const SizedBox(height: 4),

                            Text(
                              _traducirEstado(estado),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: estado == "APPROVED" ? Colors.green : Colors.red,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }


  /// **🔹 Construye una tarjeta en Móvil**
  Widget _buildTransactionCard(QueryDocumentSnapshot transaction) {
    var fecha = (transaction["createdAt"] as Timestamp).toDate();
    var formattedDate = DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es_CO').format(fecha);
    var amount = (transaction["amount"] as num).toDouble();
    var estado = transaction["status"];
    var paymentMethod = transaction["paymentMethod"] ?? "Desconocido";
    var userId = transaction["userId"];
    var transaccionId = transaction["transactionId"];
    var saldoAnterior = (transaction["saldo_anterior"] as num).toDouble();
    var saldoFinal = estado == "APPROVED" ? saldoAnterior + amount : saldoAnterior;
    var formattedAmount = "\$${NumberFormat("#,###", "es_CO").format(amount)}";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: blanco,
        surfaceTintColor: blanco,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              estado == "DECLINED"
                  ? Text(formattedAmount, style: const TextStyle(color: Colors.red, fontSize: 14, decoration: TextDecoration.lineThrough))
                  : Text(formattedAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 5),
              Text("$formattedDate - $paymentMethod", style: const TextStyle(fontSize: 12)),
              FutureBuilder<String>(
                future: _getUserName(userId),
                builder: (context, snapshot) {
                  return Text("Usuario: ${snapshot.data ?? "Cargando..."}", style: const TextStyle(fontSize: 12, color: Colors.black));
                },
              ),

              Text("Saldo Anterior: \$${NumberFormat("#,###", "es_CO").format(saldoAnterior)}", style: const TextStyle(fontSize: 10)),
              Text("Saldo Final: \$${NumberFormat("#,###", "es_CO").format(saldoFinal)}", style: const TextStyle(fontSize: 10)),
              Text("No. Transacción: $transaccionId", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                _traducirEstado(estado),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: estado == "APPROVED" ? Colors.green : Colors.red),
              ),

            ],
          ),
        ),
      ),
    );
  }



  /// **🔹 Obtiene el nombre del usuario desde Firestore**
  Future<String> _getUserName(String userId) async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection("Drivers").doc(userId).get();
      if (userDoc.exists) {
        var nombre = userDoc["01_Nombres"];
        var apellido = userDoc["02_Apellidos"];
        return "$nombre $apellido";
      } else {
        return "Usuario desconocido";
      }
    } catch (e) {
      return "Error al cargar";
    }
  }


}

String _traducirEstado(String status) {
  switch (status) {
    case "APPROVED":
      return "Aprobado";
    case "DECLINED":
      return "Rechazado";
    default:
      return "Pendiente";
  }
}

