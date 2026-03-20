import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../common/main_layout.dart';

class VehiculosAdminPage extends StatefulWidget {
  const VehiculosAdminPage({super.key});

  @override
  State<VehiculosAdminPage> createState() => _VehiculosAdminPageState();
}

class _VehiculosAdminPageState extends State<VehiculosAdminPage> {

  List vehiculos = [];
  String searchQuery = "";
  String filterEstado = "";

  @override
  void initState() {
    super.initState();
    fetchVehiculos();
  }

  Future<void> fetchVehiculos() async {

    final snapshot = await FirebaseFirestore.instance
        .collectionGroup("vehiculos")
        .get();

    vehiculos = snapshot.docs.map((doc) {
      final data = doc.data();
      data["id"] = doc.id;
      data["driverId"] = doc.reference.parent.parent?.id;
      return data;
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    List filtered = vehiculos.where((v) {

      bool matchSearch = searchQuery.isEmpty ||
          ((v["18_Placa"] ?? v["placa"] ?? v["id"] ?? "")
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()));

      bool matchEstado = true;

      if (filterEstado.isNotEmpty) {
        matchEstado = (v["estado_documentos"] ?? "") == filterEstado;
      }

      return matchSearch && matchEstado;

    }).toList();

    return MainLayout(
      pageTitle: "Vehículos",
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [

              const SizedBox(height: 10),

              /// 🔍 BUSCADOR
              _buildSearch(),

              const SizedBox(height: 10),

              /// 🎯 FILTROS
              _buildFiltros(),

              const SizedBox(height: 10),

              /// 📊 TOTAL
              Text("Total: ${filtered.length}"),

              const SizedBox(height: 10),

              /// 📋 LISTA
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {

                    final v = filtered[i];

                    return Card(
                      child: ListTile(

                        title: Text(
                          (v["18_Placa"] ?? v["placa"] ?? v["id"] ?? "Sin placa").toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Text("Estado: ${v["estado_documentos"] ?? "sin estado"}"),

                        trailing: Icon(
                          _iconEstado(v["estado_documentos"]),
                          color: _colorEstado(v["estado_documentos"]),
                        ),

                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "detalle_vehiculo_page",
                            arguments: v,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔍 BUSCADOR
  Widget _buildSearch() {
    return TextField(
      decoration: const InputDecoration(
        labelText: "Buscar por placa",
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (v) {
        setState(() {
          searchQuery = v;
        });
      },
    );
  }

  /// 🎯 FILTROS
  Widget _buildFiltros() {
    return Wrap(
      spacing: 10,
      children: [

        _btnFiltro("procesando", Colors.orange),
        _btnFiltro("aprobado", Colors.green),
        _btnFiltro("rechazado", Colors.red),

        IconButton(
          onPressed: () {
            setState(() {
              filterEstado = "";
            });
          },
          icon: const Icon(Icons.refresh),
        )
      ],
    );
  }

  Widget _btnFiltro(String estado, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () {
        setState(() {
          filterEstado = estado;
        });
      },
      child: Text(estado, style: const TextStyle(color: Colors.white)),
    );
  }

  IconData _iconEstado(String? estado) {
    switch (estado) {
      case "aprobado":
        return Icons.check_circle;
      case "rechazado":
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case "aprobado":
        return Colors.green;
      case "rechazado":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}