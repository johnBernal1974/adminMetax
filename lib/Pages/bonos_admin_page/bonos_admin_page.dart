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

  final Map<String, Map<String, dynamic>>
  _cacheDrivers = {};

  bool isDesktop(BuildContext context) {

    return MediaQuery.of(context)
        .size
        .width >= 1200;
  }

  Future<Map<String, dynamic>>
  _getDriverData(
      String idDriver,
      ) async {

    if (_cacheDrivers
        .containsKey(idDriver)) {

      return _cacheDrivers[idDriver]!;
    }

    final snap =

    await FirebaseFirestore.instance

        .collection('Drivers')

        .doc(idDriver)

        .get();

    final data =
        snap.data() ?? {};

    _cacheDrivers[idDriver] = {

      'nombre':

      '${data['01_Nombres'] ?? ''} '
          '${data['02_Apellidos'] ?? ''}'
          .trim()
          .isEmpty

          ? 'Conductor'

          : '${data['01_Nombres'] ?? ''} '
          '${data['02_Apellidos'] ?? ''}'
          .trim(),

      'celular':

      data['07_Celular']
          ?? '',
    };

    return _cacheDrivers[idDriver]!;
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

                  StreamBuilder<

                      QuerySnapshot<Map<String, dynamic>>>(

                    stream:

                    FirebaseFirestore.instance

                        .collection('TravelHistory')

                        .where(
                      'tarifaDescuento',
                      isGreaterThan: 0,
                    )

                        .where(
                      'bonoPagado',
                      isEqualTo: false,
                    )

                        .snapshots(),

                    builder:
                        (context, snapshot) {

                      if (!snapshot.hasData) {

                        return const Center(
                          child:
                          CircularProgressIndicator(),
                        );
                      }

                      final docs =
                          snapshot.data!.docs;

                      final Map<String,
                          Map<String, dynamic>>
                      agrupados = {};

                      for (final doc in docs) {

                        final data = doc.data();

                        final idDriver =

                        (data['idDriver'] ?? '')
                            .toString();

                        if (idDriver.isNotEmpty &&
                            !_cacheDrivers
                                .containsKey(idDriver)) {

                          _getDriverData(idDriver)
                              .then((_) {

                            if (mounted) {
                              setState(() {});
                            }
                          });
                        }
                      }

                      for (final doc in docs) {

                        final data = doc.data();

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

                          agrupados[idDriver] = {

                            'idDriver': idDriver,

                            'nombre':

                            _cacheDrivers[idDriver]
                            ?['nombre']

                                ?? 'Conductor',

                            'celular':

                            _cacheDrivers[idDriver]
                            ?['celular']

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

                      final conductores =

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

                      if (conductores.isEmpty) {

                        return const Center(

                          child: Text(
                            'No hay bonos pendientes',
                          ),
                        );
                      }

                      return isDesktop(context)

                          ? _buildTable(
                        conductores,
                      )

                          : _buildCards(
                        conductores,
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

  Widget _buildTable(
      List<Map<String, dynamic>>
      conductores,
      ) {

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

  Widget _buildCards(
      List<Map<String, dynamic>>
      conductores,
      ) {

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