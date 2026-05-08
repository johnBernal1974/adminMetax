import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/main_layout.dart';

class HistorialPorteriaPage extends StatelessWidget {
  const HistorialPorteriaPage({super.key});

  @override
  Widget build(BuildContext context) {

    final args =
    ModalRoute.of(context)!.settings.arguments
    as Map<String, dynamic>;

    final String idPorteria = args['id'];
    final Map<String, dynamic> data = args['data'];

    final String nombreConjunto =
    (data['nombreConjunto'] ?? '').toString();

    final numberFormat = NumberFormat("#,##0", "es_ES");

    return MainLayout(
      pageTitle: "Historial Portería",
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Row(
              children: [
                IconButton(
                  tooltip: "Regresar",

                  icon: const Icon(Icons.arrow_back),

                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const Icon(Icons.history, size: 28),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        nombreConjunto,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Historial de viajes",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),

                    ],
                  ),
                ),

              ],
            ),

            const SizedBox(height: 20),

            /// LISTA
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('TravelHistory')
                    .where(
                  'nombreConjunto',
                  isEqualTo: nombreConjunto,
                )
                    .orderBy(
                  'solicitudViaje',
                  descending: true,
                )
                    .snapshots(),

                builder: (context, snapshot) {

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {

                    return const Center(
                      child: Text(
                        "No hay viajes registrados",
                      ),
                    );
                  }

                  final viajes = snapshot.data!.docs;

                  return LayoutBuilder(
                    builder: (context, constraints) {

                      final esDesktop =
                          constraints.maxWidth > 900;

                      if (esDesktop) {
                        return _tablaDesktop(
                          viajes,
                          numberFormat,
                        );
                      }

                      return _cardsMovil(
                        viajes,
                        numberFormat,
                      );

                    },
                  );

                },
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// =========================================
  /// TABLA DESKTOP
  /// =========================================

  Widget _tablaDesktop(
      List viajes,
      NumberFormat numberFormat,
      ) {

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(

        columnSpacing: 24,

        columns: const [

          DataColumn(
            label: Text(
              "N° Viaje",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          DataColumn(
            label: Text(
              "Fecha",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          DataColumn(
            label: Text(
              "Origen",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          DataColumn(
            label: Text(
              "Destino",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          DataColumn(
            label: Text(
              "Tarifa",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        ],

        rows: viajes.map<DataRow>((doc) {

          final data =
          doc.data() as Map<String, dynamic>;

          return DataRow(

            cells: [

              DataCell(
                Text(
                  data['numeroViaje'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              DataCell(
                Text(
                  _formatTimestamp(
                    data['solicitudViaje'],
                  ),
                ),
              ),

              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    data['from'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    data['to'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              DataCell(
                Text(
                  '\$${numberFormat.format(data['tarifa'] ?? 0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            ],

          );

        }).toList(),

      ),
    );
  }

  /// =========================================
  /// CARDS MOVIL
  /// =========================================

  Widget _cardsMovil(
      List viajes,
      NumberFormat numberFormat,
      ) {

    return ListView.builder(
      itemCount: viajes.length,

      itemBuilder: (context, index) {

        final doc = viajes[index];

        final data =
        doc.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  data['numeroViaje'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _formatTimestamp(
                    data['solicitudViaje'],
                  ),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),

                const Divider(height: 24),

                _item(
                  "Origen",
                  data['from'] ?? '',
                ),

                const SizedBox(height: 10),

                _item(
                  "Destino",
                  data['to'] ?? '',
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [

                    const Text(
                      "Tarifa",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      '\$${numberFormat.format(data['tarifa'] ?? 0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                  ],
                )

              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _item(
      String label,
      String value,
      ) {

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 4),

        Text(value),

      ],
    );
  }

  static String _formatTimestamp(dynamic timestamp) {

    if (timestamp == null) return '—';

    try {

      final date =
      (timestamp as Timestamp).toDate();

      return DateFormat(
        'dd/MM/yyyy hh:mm a',
      ).format(date);

    } catch (e) {

      return '—';

    }
  }
}