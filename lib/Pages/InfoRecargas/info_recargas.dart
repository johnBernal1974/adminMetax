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
  Map<String, String> _userNames = {};
  Map<String, bool> _expandedCards = {};
  Map<String, String> _userPlates = {};


  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "Transacciones",
      content: Center(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("recargas")
                  .orderBy("createdAt", descending: true)
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
        ),
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
                "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana])}",
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
                "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana])}",
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
                    DataColumn(label: Text("Placa", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Método Pago", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Saldo Anterior", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Monto", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Saldo Final", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Referencia de pago", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Estado", style: TextStyle(fontSize: 12))),
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
                      DataCell(FutureBuilder<String>(
                        future: _getUserPlate(userId),
                        builder: (context, snapshot) {
                          return Text(snapshot.data ?? "Cargando...", style: const TextStyle(fontSize: 12));
                        },
                      )),


                      DataCell(Text(paymentMethod, style: const TextStyle(fontSize: 10))),
                      DataCell(Text("\$${NumberFormat("#,###", "es_CO").format(saldoAnterior)}", style: const TextStyle(fontSize: 11),)),
                      DataCell(estado == "DECLINED"
                          ? Text(formattedAmount, style: const TextStyle(color: Colors.red, fontSize: 11, decoration: TextDecoration.lineThrough))
                          : Text(formattedAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataCell(Text("\$${NumberFormat("#,###", "es_CO").format(saldoFinal)}", style: const TextStyle(fontSize: 11),)),
                      DataCell(Text(transactionId, style: const TextStyle(fontSize: 11))),
                      DataCell(Text(
                        _traducirEstado(estado),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: estado == "APPROVED" ? Colors.green : Colors.red,
                          fontSize: 11
                        ),
                      )),
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
              FutureBuilder<String>(
                future: _getUserPlate(userId),
                builder: (context, snapshot) {
                  return Text(
                    "Placa: ${snapshot.data ?? "Cargando..."}",
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  );
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

  /// **🔹 Widget reutilizable para mostrar filas de detalles**
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
  Future<String> _getUserPlate(String userId) async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection("Drivers").doc(userId).get();
      if (userDoc.exists) {
        return userDoc["18_Placa"] ?? "Sin placa";
      }
      return "Sin placa";
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

