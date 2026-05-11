import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../common/main_layout.dart';

class BonosAdminPage extends StatefulWidget {
  const BonosAdminPage({super.key});

  @override
  State<BonosAdminPage> createState() =>
      _BonosAdminPageState();
}

class _BonosAdminPageState
    extends State<BonosAdminPage> {

  bool loading = true;

  List<Map<String, dynamic>>
  conductores = [];

  bool isDesktop(BuildContext context) {

    return MediaQuery.of(context)
        .size
        .width >= 1200;
  }

  @override
  void initState() {
    super.initState();
    cargarBonos();
  }

  Future<void> cargarBonos() async {

    setState(() {
      loading = true;
    });

    final snap =
    await FirebaseFirestore.instance

        .collection('TravelHistory')

        .where(
      'tarifaDescuento',
      isGreaterThan: 0,
    )

        .where(
      'bonoPagado',
      isEqualTo: false,
    )

        .get();

    final Map<String,
        Map<String, dynamic>>
    agrupados = {};

    for (final doc in snap.docs) {

      final data = doc.data();
      print(data);

      final idDriver =
      (data['idDriver'] ?? '')
          .toString();

      if (idDriver.isEmpty) {
        continue;
      }

      final bono =

          (data['tarifaDescuento']
          as num?)

              ?.toDouble()

              ?? 0;

      if (!agrupados
          .containsKey(idDriver)) {

        final driverDoc =

        await FirebaseFirestore.instance

            .collection('Drivers')

            .doc(idDriver)

            .get();

        final driverData =
        driverDoc.data();

        agrupados[idDriver] = {

          'idDriver': idDriver,

          'nombre':

          '${driverData?['01_Nombres'] ?? ''} '

              '${driverData?['02_Apellidos'] ?? ''}',

          'celular':

          driverData?['07_Celular']
              ?? '',

          'total': 0.0,

          'cantidad': 0,
        };
      }

      agrupados[idDriver]!['total']
      += bono;

      agrupados[idDriver]!['cantidad']
      += 1;
    }

    conductores =
        agrupados.values.toList();

    conductores.sort((a, b) {

      final totalA =
      (a['total'] as double);

      final totalB =
      (b['total'] as double);

      return totalB.compareTo(
        totalA,
      );
    });

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return MainLayout(

      pageTitle:
      'Bonos pendientes',

      content: Align(

        alignment:
        Alignment.topCenter,

        child: SizedBox(

          width:

          isDesktop(context)

              ? 1100

              : double.infinity,

          child: Padding(

            padding:
            const EdgeInsets.all(20),

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                const Text(

                  'Viajes con promoción de conductores',

                  style: TextStyle(

                    fontSize: 26,

                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                Text(

                  'Administra los bonos pendientes generados por promociones.',

                  style: TextStyle(

                    color: Colors.grey.shade700,

                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(

                  child:

                  loading

                      ? const Center(

                    child:
                    CircularProgressIndicator(),
                  )

                      : conductores.isEmpty

                      ? const Center(

                    child: Text(
                      'No hay bonos pendientes',
                    ),
                  )

                      : isDesktop(context)

                      ? _buildTable()

                      : _buildCards(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {

    return SingleChildScrollView(

      scrollDirection: Axis.horizontal,

      child: DataTable(

        columns: const [

          DataColumn(

            label: Text(

              'Conductor',

              style: TextStyle(

                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),

          DataColumn(

            label: Text(

              'Bonos pendientes',

              style: TextStyle(

                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),

          DataColumn(

            label: Text(

              'Valor total',

              style: TextStyle(

                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),

          DataColumn(

            label: Text(

              'Acción',

              style: TextStyle(

                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),
        ],

        rows:

        conductores.map((item) {

          return DataRow(

            onSelectChanged: (_) async {

              await Navigator.pushNamed(

                context,

                'detalle_bonos_driver',

                arguments: item,
              );

              await cargarBonos();
            },

            cells: [

              DataCell(

                Text(

                  item['nombre'],

                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              DataCell(

                Text(

                  '${item['cantidad']}',
                ),
              ),

              DataCell(

                Text(

                  '\$ ${item['total'].toInt()}',

                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),

              const DataCell(

                Icon(
                  Icons.visibility,
                ),
              ),
            ],
          );

        }).toList(),
      ),
    );
  }

  Widget _buildCards() {

    return ListView.builder(

      itemCount:
      conductores.length,

      itemBuilder:
          (context, index) {

        final item =
        conductores[index];

        return Container(

          margin:
          const EdgeInsets.only(
            bottom: 14,
          ),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius:
            BorderRadius.circular(
              16,
            ),

            border: Border.all(
              color:
              Colors.grey.shade300,
            ),
          ),

          child: Padding(

            padding:
            const EdgeInsets.all(
              16,
            ),

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                Text(

                  item['nombre'],

                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.w900,

                    fontSize: 16,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(

                  '${item['cantidad']} '
                      'bonos pendientes',
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(

                  '\$ ${item['total'].toInt()}',

                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.w900,

                    fontSize: 24,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                SizedBox(

                  width:
                  double.infinity,

                  child:
                  ElevatedButton.icon(

                    onPressed: () async {

                      await Navigator.pushNamed(

                        context,

                        'detalle_bonos_driver',

                        arguments: item,
                      );

                      await cargarBonos();
                    },

                    icon: const Icon(
                      Icons.visibility,
                      color: Colors.black,
                    ),

                    label: const Text(

                      'Ver bonos',

                      style: TextStyle(

                        color:
                        Colors.black,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    style:
                    ElevatedButton
                        .styleFrom(

                      backgroundColor:
                      Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}