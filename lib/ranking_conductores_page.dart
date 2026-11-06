
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RankingConductoresPage extends StatelessWidget {
  const RankingConductoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de conductores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(
                context,
                'general_page',
              );
            }
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('Drivers')
            .where(
          'Verificacion_Status',
          isEqualTo: 'activado',
        )
            .orderBy('30_Numero_viajes', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error.toString();

            debugPrint('====================================');
            debugPrint('ERROR RANKING CONDUCTORES');
            debugPrint(error);
            debugPrint('====================================');

            return Center(
              child: SelectableText(
                'Error al consultar el ranking:\n$error',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final conductores = snapshot.data!.docs;

          if (conductores.isEmpty) {
            return const Center(
              child: Text('No hay conductores para mostrar.'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Top ${conductores.length} conductores activados',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 20,
                      ),
                      itemCount: conductores.length,
                      itemBuilder: (context, index) {
                        final data = conductores[index].data();

                        // NOMBRE REAL EN FIRESTORE
                        final nombres =
                        (data['01_Nombres'] ?? '').toString().trim();

                        final apellidos =
                        (data['02_Apellidos'] ?? '').toString().trim();

                        final nombre =
                        '$nombres $apellidos'.trim();

                        // FOTO DE PERFIL
                        final foto =
                        (data['image'] ?? '').toString().trim();

                        // PLACA DEL VEHÍCULO ACTIVO
                        final vehiculoActivo =
                        (data['vehiculoActivoId'] ?? '')
                            .toString()
                            .trim();

                        final placaAnterior =
                        (data['placaActiva'] ?? '')
                            .toString()
                            .trim();

                        final placa = vehiculoActivo.isNotEmpty
                            ? vehiculoActivo
                            : placaAnterior;

                        // VIAJES ACUMULADOS
                        final viajes =
                            (data['30_Numero_viajes'] as num?)
                                ?.toInt() ??
                                0;

                        final posicion = index + 1;

                        Color colorPosicion;

                        if (posicion == 1) {
                          colorPosicion = Colors.amber.shade700;
                        } else if (posicion == 2) {
                          colorPosicion = Colors.blueGrey;
                        } else if (posicion == 3) {
                          colorPosicion = Colors.brown;
                        } else {
                          colorPosicion = Colors.grey.shade600;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                // POSICIÓN
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colorPosicion,
                                  child: Text(
                                    '$posicion',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // FOTO DEL CONDUCTOR
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey.shade200,
                                  child: ClipOval(
                                    child: foto.isNotEmpty
                                        ? Image.network(
                                      foto,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                          ) {
                                        return const Icon(
                                          Icons.person,
                                          size: 28,
                                          color: Colors.grey,
                                        );
                                      },
                                    )
                                        : const Icon(
                                      Icons.person,
                                      size: 28,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // NOMBRE Y PLACA
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre.isEmpty
                                            ? 'Conductor sin nombre'
                                            : nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Row(
                                        children: [
                                          Icon(
                                            Icons.directions_car,
                                            size: 15,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              placa.isEmpty
                                                  ? 'Sin placa activa'
                                                  : placa,
                                              overflow:
                                              TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // TOTAL DE VIAJES
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$viajes',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Text(
                                      'viajes',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
