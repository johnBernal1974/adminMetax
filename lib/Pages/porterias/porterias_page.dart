import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../common/main_layout.dart';
import '../../src/color.dart';

class PorteriasPage extends StatefulWidget {
  const PorteriasPage({super.key});

  @override
  State<PorteriasPage> createState() => _PorteriasPageState();
}

class _PorteriasPageState extends State<PorteriasPage> {

  final TextEditingController _buscarController = TextEditingController();

  String textoBusqueda = "";

  @override
  Widget build(BuildContext context) {

    return MainLayout(
      pageTitle: "Porterías",
      content: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    "Porterías registradas",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text(
                      "Registrar",
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        'registro_porteria_page',
                      );
                    },
                  )

                ],
              ),

              const SizedBox(height: 20),

              /// BUSCADOR
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _buscarController,
                  onChanged: (value) {
                    setState(() {
                      textoBusqueda = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Buscar portería...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// LISTA
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Porterias')
                      .orderBy('fechaRegistro', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    var porterias = snapshot.data!.docs;

                    /// FILTRO BUSQUEDA
                    porterias = porterias.where((doc) {

                      final data = doc.data() as Map<String, dynamic>;

                      final nombre = (data['nombreConjunto'] ?? "").toString().toLowerCase();
                      final direccion = (data['direccion'] ?? "").toString().toLowerCase();
                      final ciudad = (data['ciudad'] ?? "").toString().toLowerCase();

                      return nombre.contains(textoBusqueda) ||
                          direccion.contains(textoBusqueda) ||
                          ciudad.contains(textoBusqueda);

                    }).toList();

                    if (porterias.isEmpty) {
                      return const Center(
                        child: Text("No hay resultados"),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {

                        final esDesktop = constraints.maxWidth > 900;

                        if (esDesktop) {
                          return _tablaPorterias(porterias);
                        } else {
                          return _cardsPorterias(porterias);
                        }

                      },
                    );

                  },
                ),
              )

            ],
          ),
        ),
      ),
    );
  }

  /// =========================
  /// TABLA DESKTOP
  /// =========================

  Widget _tablaPorterias(List porterias) {

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(

        columnSpacing: 50,

        columns: const [

          DataColumn(label: Text("Conjunto")),
          DataColumn(label: Text("Portería")),
          DataColumn(label: Text("Ciudad")),
          DataColumn(label: Text("Teléfono")),
          DataColumn(label: Text("Tipo")),
          DataColumn(label: Text("Estado")),
          DataColumn(label: Text("Acciones")),

        ],

        rows: porterias.map((doc) {

          final data = doc.data() as Map<String, dynamic>;
          final id = doc.id;

          final activa = data['activa'] ?? true;

          return DataRow(

            cells: [

              DataCell(Text(data['nombreConjunto'] ?? "")),

              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text(
                      data['nombrePorteria'] ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      data['direccion'] ?? "",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),

                  ],
                ),
              ),

              DataCell(Text(data['ciudad'] ?? "")),

              DataCell(Text(data['telefono'] ?? "")),

              DataCell(Text(data['tipoPorteria'] ?? "")),

              DataCell(
                Icon(
                  activa ? Icons.check_circle : Icons.cancel,
                  color: activa ? Colors.green : Colors.red,
                ),
              ),

              DataCell(
                Row(
                  children: [

                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {

                        Navigator.pushNamed(
                          context,
                          'editar_porteria_page',
                          arguments: {
                            "id": id,
                            "data": data,
                          },
                        );

                      },
                    ),

                    IconButton(
                      icon: Icon(
                        activa ? Icons.block : Icons.check,
                      ),
                      onPressed: () async {

                        await FirebaseFirestore.instance
                            .collection('Porterias')
                            .doc(id)
                            .update({
                          "activa": !activa
                        });

                      },
                    )

                  ],
                ),
              )

            ],

          );

        }).toList(),

      ),
    );
  }

  /// =========================
  /// CARDS MOVIL
  /// =========================

  Widget _cardsPorterias(List porterias) {

    return ListView.builder(
      itemCount: porterias.length,
      itemBuilder: (context, index) {

        final doc = porterias[index];
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;

        final activa = data['activa'] ?? true;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [

                    const Icon(Icons.apartment),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        data['nombreConjunto'] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    Icon(
                      activa
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: activa
                          ? Colors.green
                          : Colors.red,
                    )

                  ],
                ),

                const SizedBox(height: 8),

                Text("Portería: ${data['nombrePorteria'] ?? ""}"),

                Text(data['direccion'] ?? ""),

                Text("${data['barrio']} - ${data['ciudad']}"),

                Text("Tel: ${data['telefono']}"),

                Text("Tipo: ${data['tipoPorteria']}"),

                const SizedBox(height: 10),

                Row(
                  children: [

                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Editar"),
                      onPressed: () {

                        Navigator.pushNamed(
                          context,
                          'editar_porteria_page',
                          arguments: {
                            "id": id,
                            "data": data,
                          },
                        );

                      },
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton.icon(
                      icon: Icon(
                        activa
                            ? Icons.block
                            : Icons.check,
                      ),
                      label: Text(
                        activa
                            ? "Desactivar"
                            : "Activar",
                      ),
                      onPressed: () async {

                        await FirebaseFirestore.instance
                            .collection('Porterias')
                            .doc(id)
                            .update({
                          "activa": !activa
                        });

                      },
                    )

                  ],
                )

              ],
            ),
          ),
        );

      },
    );
  }

}