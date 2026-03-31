import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/main_layout.dart';
import '../Pages/DriverDetailPage/driver_detail_page.dart';
import '../models/conductor_model.dart';
import '../src/color.dart';

class VehiculoDetailAdminPage extends StatefulWidget {
  const VehiculoDetailAdminPage({super.key});

  @override
  State<VehiculoDetailAdminPage> createState() => _VehiculoDetailAdminPageState();
}

class _VehiculoDetailAdminPageState extends State<VehiculoDetailAdminPage> {

  Map<String, dynamic> data = {};
  Map<String, List<String>> errores = {};

  late String placaGlobal;
  late String driverIdGlobal;

  Map<String, List<String>> erroresFirestore = {};
  Map<String, List<String>> erroresSeleccionados = {};



  final Map<String, String> nombresCampos = {
    "foto_tarjeta_propiedad_delantera": "Tarjeta de propiedad (frontal)",
    "foto_tarjeta_propiedad_trasera": "Tarjeta de propiedad (trasera)",
  };


  final Map<String, List<String>> opcionesErrores = {
    "foto_tarjeta_propiedad_delantera": [
      "Foto borrosa",
      "Foto recortada",
      "No corresponde al vehículo",
    ],
    "foto_tarjeta_propiedad_trasera": [
      "Foto borrosa",
      "Foto recortada",
      "No corresponde al vehículo",
    ],
  };

  bool _hayErroresSeleccionados() {
    return errores.values.any((lista) {
      return lista.isNotEmpty;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments as VehiculoDetailArgs;

    final vehiculo = args.vehiculo;
    final driverId = args.driverId;

    /// 🔥 SI QUIERES USARLO EN TODA LA CLASE
    data = vehiculo;

    /// 🔥 PROCESAR ERRORES CORRECTAMENTE
    final rawErrores = vehiculo["errores"];

    if (rawErrores != null && rawErrores is Map) {
      erroresFirestore = rawErrores.map<String, List<String>>((key, value) {
        return MapEntry(
          key.toString(),
          List<String>.from(value ?? []),
        );
      });
    } else {
      erroresFirestore = {};
    }
    /// 🔥 sincronizar selección con Firestore
    erroresSeleccionados = Map.from(erroresFirestore);
  }

  @override
  Widget build(BuildContext context) {

    String placa = (data["18_Placa"] ?? data["id"] ?? "").toString();
    String? driverId = data["driverId"];
    if (driverId == null || driverId.isEmpty) {
      return const Center(child: Text("driverId no disponible"));
    }

    placaGlobal = placa;
    driverIdGlobal = driverId;

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Drivers")
            .doc(driverId)
            .collection("vehiculos")
            .doc(placa)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docData = snapshot.data!.data() as Map<String, dynamic>;

          /// 🔥 ACTUALIZA DATA EN TIEMPO REAL
          data = {
            ...docData,

            /// 🔥 SOLO conservar inputs que el admin está escribiendo
            "20_Numero_Soat": data["20_Numero_Soat"],
            "22_Numero_Tecno": data["22_Numero_Tecno"],
            "24_Numero_Tarjeta_Propiedad": data["24_Numero_Tarjeta_Propiedad"],
          };

          /// 🔥 PROCESAR ERRORES EN TIEMPO REAL
          final rawErrores = docData["errores"];

          /// 🔥 SOLO cargar errores UNA VEZ (no pisar selección del usuario)
          if (errores.isEmpty) {
            if (rawErrores != null && rawErrores is Map) {
              errores = rawErrores.map<String, List<String>>((key, value) {
                return MapEntry(
                  key.toString(),
                  List<String>.from(value ?? []),
                );
              });
            } else {
              errores = {};
            }
          }

          final fotosAprobadas =
              data["27_Tarjeta_Propiedad_Delantera_foto"] == "aprobada" &&
                  data["28_Tarjeta_Propiedad_Trasera_foto"] == "aprobada";

          return MainLayout(
            pageTitle: "Detalle vehículo",
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// 🚗 PLACA
                        Text(
                          "Placa No. $placa",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        /// 📊 ESTADO
                        Row(
                          children: [
                            const Text(
                              "Estado: ",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            _estadoWidget(data["estado_documentos"]),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// =========================
                        /// 🚗 DATOS VEHÍCULO
                        /// =========================
                        _seccion("Datos del vehículo"),

                        // 👇 TODO TU CONTENIDO SE QUEDA IGUAL

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;

                      if (isMobile) {
                        /// 📱 MÓVIL → en columna
                        return Column(
                          children: [
                            _dropdown(
                              "Marca",
                              "15_Marca",
                              [
                                "Hyundai Atos",
                                "Hyundai Grand I10",
                                "Kia Picanto Ekotaxi",
                                "Kia Picanto Ekotaxi LX",
                                "Kia Morning",
                                "Kia Sephia",
                                "Kia Super VIP",
                                "Suzuki New Alto K10",
                                "FAW R7 SUV",
                                "FAW taxi V5",
                                "Hyundai Accent",
                                "Renault Logan",
                                "Renault Clio Express",
                                "Chevrolet Chevy Taxi",
                                "Otro",
                              ],
                            ),
                            const SizedBox(height: 10),
                            _input("Modelo", "17_Modelo"),
                          ],
                        );
                      } else {
                        /// 💻 WEB / TABLET → en fila
                        return Row(
                          children: [
                            Expanded(
                              flex: 2, // 🔥 Marca más grande
                              child: _dropdown(
                                "Marca",
                                "15_Marca",
                                [
                                  "Hyundai Atos",
                                  "Hyundai Grand I10",
                                  "Kia Picanto Ekotaxi",
                                  "Kia Picanto Ekotaxi LX",
                                  "Kia Morning",
                                  "Kia Sephia",
                                  "Kia Super VIP",
                                  "Suzuki New Alto K10",
                                  "FAW R7 SUV",
                                  "FAW taxi V5",
                                  "Hyundai Accent",
                                  "Renault Logan",
                                  "Renault Clio Express",
                                  "Chevrolet Chevy Taxi",
                                  "Otro",
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              flex: 1, // 🔥 Modelo más pequeño
                              child: _input("Modelo", "17_Modelo"),
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;

                      if (isMobile) {
                        /// 📱 MÓVIL → en columna
                        return Column(
                          children: [
                            _dropdown(
                              "Color",
                              "16_Color",
                              ["Amarillo", "Blanco"],
                            ),
                            const SizedBox(height: 10),
                            _dropdown(
                              "Tipo vehículo",
                              "14_Tipo_Vehiculo",
                              ["Tipo automovil", "Tipo camioneta"],
                            ),
                          ],
                        );
                      } else {
                        /// 💻 WEB / TABLET → en fila
                        return Row(
                          children: [
                            Expanded(
                              child: _dropdown(
                                "Color",
                                "16_Color",
                                ["Amarillo", "Blanco"],
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _dropdown(
                                "Tipo vehículo",
                                "14_Tipo_Vehiculo",
                                ["Tipo automovil", "Tipo camioneta"],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;

                      if (isMobile) {
                        /// 📱 MÓVIL → en columna
                        return Column(
                          children: [
                            _dropdown(
                              "Tipo servicio",
                              "19_Tipo_Servicio",
                              ["Público", "Operación Nacional"],
                            ),
                            const SizedBox(height: 10),
                            _input(
                              "Licencia de tránsito",
                              "24_Numero_Tarjeta_Propiedad",
                            ),
                          ],
                        );
                      } else {
                        /// 💻 WEB / TABLET → en fila
                        return Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: _dropdown(
                                "Tipo servicio",
                                "19_Tipo_Servicio",
                                ["Público", "Operación Nacional"],
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              flex: 2, // 🔥 más espacio al input
                              child: _input(
                                "Licencia de tránsito",
                                "24_Numero_Tarjeta_Propiedad",
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                 /// =========================
                  /// 📸 FOTOS
                  /// =========================
                  _seccion("Fotos"),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;

                      if (isMobile) {
                        /// 📱 MÓVIL → en columna
                        return Column(
                          children: [
                            _foto(
                              "Tarjeta propiedad delantera",
                              data["foto_tarjeta_propiedad_delantera"],
                              data["27_Tarjeta_Propiedad_Delantera_foto"],
                              "foto_tarjeta_propiedad_delantera",
                            ),
                            const SizedBox(height: 15),
                            _foto(
                              "Tarjeta propiedad trasera",
                              data["foto_tarjeta_propiedad_trasera"],
                              data["28_Tarjeta_Propiedad_Trasera_foto"],
                              "foto_tarjeta_propiedad_trasera",
                            ),
                          ],
                        );
                      } else {
                        /// 💻 WEB → en fila
                        return Row(
                          children: [
                            Expanded(
                              child:_foto(
                                "Tarjeta propiedad delantera",
                                data["foto_tarjeta_propiedad_delantera"],
                                data["27_Tarjeta_Propiedad_Delantera_foto"],
                                "foto_tarjeta_propiedad_delantera",
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: _foto(
                                "Tarjeta propiedad trasera",
                                data["foto_tarjeta_propiedad_trasera"],
                                data["28_Tarjeta_Propiedad_Trasera_foto"],
                                "foto_tarjeta_propiedad_trasera",
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  /// =========================
                  /// ❌ ERRORES
                  /// =========================
                  if (errores.isNotEmpty) ...[
                    _seccion("Errores"),
                    ...errores.entries.map((e) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: e.value.map((err) {
                          return Text("• $err", style: const TextStyle(color: Colors.red));
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 10),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;

                      if (isMobile) {
                        return Column(
                          children: [
                            _inputError("foto_tarjeta_propiedad_delantera"),
                            _inputError("foto_tarjeta_propiedad_trasera"),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: _inputError("foto_tarjeta_propiedad_delantera"),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _inputError("foto_tarjeta_propiedad_trasera"),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                        Row(
                          children: [

                            /// 🔴 DELANTERA
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => rechazarDocumento(
                                  driverId,
                                  placa,
                                  "foto_tarjeta_propiedad_delantera",
                                ),
                                child: const Text("Rechazar delantera", style: TextStyle(color: Colors.white)),
                              ),
                            ),

                            const SizedBox(width: 10),

                            /// 🔴 TRASERA
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => rechazarDocumento(
                                  driverId,
                                  placa,
                                  "foto_tarjeta_propiedad_trasera",
                                ),
                                child: const Text("Rechazar trasera", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: _seccionSOAT(),
                  ),
                  const SizedBox(height: 25),
                  /// =========================
                  /// 🔥 BOTONES
                  /// =========================


                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      /// 💾 GUARDAR
                      ElevatedButton.icon(
                        onPressed: () => guardarCambios(driverId, placa),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          "Guardar Cambios",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),

                      const SizedBox(width: 10),



                      /// ✅ APROBAR
                      ElevatedButton.icon(
                        onPressed: (_hayErroresSeleccionados() || !fotosAprobadas)
                            ? null
                            : () => aprobar(driverId, placa),
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                          "Aprobar vehículo",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
           ),
          ),
         ),
        );
       },
    );
  }

  List<String> validarCamposVehiculo() {
    List<String> faltantes = [];

    if ((data["15_Marca"] ?? "").toString().isEmpty) {
      faltantes.add("Marca");
    }

    if ((data["17_Modelo"] ?? "").toString().isEmpty) {
      faltantes.add("Modelo");
    }

    if ((data["16_Color"] ?? "").toString().isEmpty) {
      faltantes.add("Color");
    }

    if ((data["14_Tipo_Vehiculo"] ?? "").toString().isEmpty) {
      faltantes.add("Tipo vehículo");
    }

    if ((data["19_Tipo_Servicio"] ?? "").toString().isEmpty) {
      faltantes.add("Tipo servicio");
    }

    if ((data["24_Numero_Tarjeta_Propiedad"] ?? "").toString().isEmpty) {
      faltantes.add("Licencia de tránsito");
    }

    /// 🔥 NUEVO
    if ((data["20_Numero_Soat"] ?? "").toString().isEmpty) {
      faltantes.add("Número SOAT");
    }

    if ((data["21_Vigencia_Soat"] ?? "").toString().isEmpty) {
      faltantes.add("Vigencia SOAT");
    }

    if ((data["22_Numero_Tecno"] ?? "").toString().isEmpty) {
      faltantes.add("Número Tecnomecánica");
    }

    if ((data["23_Vigencia_Tecno"] ?? "").toString().isEmpty) {
      faltantes.add("Vigencia Tecnomecánica");
    }

    if ((data["foto_tarjeta_propiedad_delantera"] ?? "").toString().isEmpty) {
      faltantes.add("Foto tarjeta delantera");
    }

    if ((data["foto_tarjeta_propiedad_trasera"] ?? "").toString().isEmpty) {
      faltantes.add("Foto tarjeta trasera");
    }

    return faltantes;
  }

  bool campoVacio(String key) {
    return (data[key] ?? "").toString().trim().isEmpty;
  }

  Future<void> guardarCambios(String driverId, String placa) async {
    try {

      /// 🔥 1. LIMPIAR CAMPOS QUE NO VAN A FIRESTORE
      data.remove("id");
      data.remove("driverId");

      /// 🔥 2. ASEGURAR TIPO CORRECTO
      Map<String, dynamic> dataSeguro = Map<String, dynamic>.from(data);

      /// 🔥 3. GUARDAR
      await FirebaseFirestore.instance
          .collection("Drivers")
          .doc(driverId)
          .collection("vehiculos")
          .doc(placa)
          .update(dataSeguro);

      /// 🔥 4. FEEDBACK
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cambios guardados correctamente")),
      );

    } catch (e) {
      print("Error guardando: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar")),
      );
    }
  }

  Widget _estadoWidget(String? estado) {
    String texto;
    IconData icono;
    Color color;

    switch (estado) {
      case "aprobado":
        texto = "Aprobado";
        icono = Icons.check_circle;
        color = Colors.green;
        break;

      case "rechazado":
        texto = "Rechazado";
        icono = Icons.cancel;
        color = Colors.red;
        break;

      default:
        texto = "procesando";
        icono = Icons.access_time;
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _input(String label, String key) {
    final isError = campoVacio(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: (data[key] ?? "").toString(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isError ? Colors.red : null,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isError ? Colors.red : primary,
              width: 2,
            ),
          ),
        ),
        onChanged: (v) {
          setState(() {
            data[key] = v;
          });
        },
      ),
    );
  }

  Widget _dropdown(String label, String key, List<String> items) {
    final rawValue = data[key];
    final isError = campoVacio(key);

    String? currentValue;

    if (rawValue is String && items.contains(rawValue)) {
      currentValue = rawValue;
    } else {
      currentValue = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        items: items.map((e) {
          return DropdownMenuItem(value: e, child: Text(e));
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isError ? Colors.red : null,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isError ? Colors.red : primary,
              width: 2,
            ),
          ),
        ),
        onChanged: (v) {
          setState(() {
            data[key] = v;
          });
        },
      ),
    );
  }

  /// 📸 FOTO
  Widget _foto(String titulo, String? url, String? estado, String campoFoto) {


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// 🔥 TITULO + BADGE
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titulo),

            if (estado != null) _badgeEstadoFoto(estado),
          ],
        ),

        const SizedBox(height: 5),

        url != null && url.isNotEmpty
            ? GestureDetector(
          onTap: () => _verImagenGrande(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 220,
              width: 350,
              child: Image.network(
                url,
                fit: BoxFit.cover,
              ),
            ),
          ),
        )
            : const Text("Sin imagen"),

        if (estado != "aprobada") ...[
          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: () => aprobarFoto(driverIdGlobal, placaGlobal, campoFoto),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              "Aprobar",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],

        const SizedBox(height: 10),
      ],
    );
  }

  Widget _badgeEstadoFoto(String estado) {
    Color color;
    String texto;
    IconData icono;

    switch (estado) {
      case "corregida":
        color = Colors.purple;
        texto = "Corregida";
        icono = Icons.refresh;
        break;

      case "tomada":
        color = Colors.grey;
        texto = "Tomada";
        icono = Icons.image;
        break;

      case "rechazada":
        color = Colors.red;
        texto = "Rechazada";
        icono = Icons.image;
        break;

      case "aprobada":
        color = Colors.green;
        texto = "Aprobada";
        icono = Icons.image;
        break;  

      default:
        color = Colors.grey;
        texto = "Sin estado";
        icono = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _verImagenGrande(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [

            /// 📸 IMAGEN GRANDE
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
              ),
            ),

            /// ❌ BOTÓN CERRAR
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionSOAT() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 TÍTULO
            _seccion("SOAT y Tecnomecánica"),

            const SizedBox(height: 10),

            isMobile
                ? Column(
              children: _contenidoSoatTecno(),
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: _contenidoSoatTecno(),
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: _botonRunt(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _contenidoSoatTecno() {
    return [

      _input("Número SOAT", "20_Numero_Soat"),

      _dateWithBadge(
        label: "Vigencia SOAT",
        key: "21_Vigencia_Soat",
        value: data["21_Vigencia_Soat"],
      ),
      const SizedBox(height: 10),

      _input("Número Tecnomecánica", "22_Numero_Tecno"),

      _dateWithBadge(
        label: "Vigencia Tecnomecánica",
        key: "23_Vigencia_Tecno",
        value: data["23_Vigencia_Tecno"],
      ),

    ];
  }

  Widget _botonRunt() {
    return SizedBox(
      height: 50,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () async {
            const url = 'https://www.runt.com.co/consultaCiudadana/#/consultaVehiculo';
            if (await canLaunch(url)) {
              await launch(url);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.add_chart_sharp, color: Colors.white),
          label: const Text('Abrir pagina RUNT', style: TextStyle(color: blanco)),
        ),
      ),
    );
  }

  Widget _dateWithBadge({
    required String label,
    required String key,
    required String? value,
  }) {
    final controller = TextEditingController(
      text: data[key] ?? "",
    );

    final isError = campoVacio(key);

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        locale: const Locale('es', 'CO'),
      );

      if (picked != null) {
        final formatted = DateFormat('dd/MM/yyyy').format(picked);

        setState(() {
          data[key] = formatted;
        });

        await FirebaseFirestore.instance
            .collection("Drivers")
            .doc(data["driverId"])
            .collection("vehiculos")
            .doc(data["id"])
            .update({key: formatted});
      }
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: pickDate,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: isError ? Colors.red : null,
              ),
              suffixIcon: const Icon(Icons.calendar_month),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isError ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        badgeVigencia(fechaBd: value),
      ],
    );
  }

  Future<void> _seleccionarFecha(String key) async {

    DateTime initialDate = DateTime.now();

    if (data[key] != null && data[key].toString().isNotEmpty) {
      try {
        initialDate = DateTime.parse(data[key]);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        data[key] = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  /// ✏️ INPUT ERROR
  Widget _inputError(String campo) {
    final labelBonito = nombresCampos[campo] ?? campo;
    final opciones = opcionesErrores[campo] ?? [];

    /// 🔥 BLINDA EL MAP (evita null y tipos raros)
    if (errores[campo] == null || errores[campo] is! List<String>) {
      errores[campo] = [];
    }

    final lista = errores[campo]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        surfaceTintColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔴 TÍTULO
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      labelBonito,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// ✅ OPCIONES
              ...opciones.map((opcion) {
                final seleccionado = lista.contains(opcion);

                return CheckboxListTile(
                  value: seleccionado,
                  title: Text(opcion),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true, // 🔥 más compacto
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (!lista.contains(opcion)) {
                          lista.add(opcion);
                        }
                      } else {
                        lista.remove(opcion);
                      }
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> rechazarDocumento(
      String driverId,
      String placa,
      String campoFoto,
      ) async {

    /// 🔥 MAPEO DE CAMPOS
    final campoEstado = campoFoto == "foto_tarjeta_propiedad_delantera"
        ? "27_Tarjeta_Propiedad_Delantera_foto"
        : "28_Tarjeta_Propiedad_Trasera_foto";

    /// 🔥 ERRORES SOLO DE ESTE CAMPO
    final erroresCampo = errores[campoFoto] ?? [];

    if (erroresCampo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar al menos un error")),
      );
      return;
    }

    /// 🔥 UPDATE LIMPIO
    await FirebaseFirestore.instance
        .collection("Drivers")
        .doc(driverId)
        .collection("vehiculos")
        .doc(placa)
        .update({

      /// 🔴 SOLO ESTE DOCUMENTO
      campoEstado: "rechazada",

      /// 🔴 SOLO ESTE ERROR
      "errores.$campoFoto": erroresCampo,

      /// 🔴 ESTADO GENERAL
      "estado_documentos": "rechazado",
    });

    Navigator.pop(context);
  }


  /// ✅ APROBAR
  Future<void> aprobar(String driverId, String placa) async {

    // 🔥 VALIDAR FOTOS APROBADAS
    final fotoDelantera = data["27_Tarjeta_Propiedad_Delantera_foto"];
    final fotoTrasera = data["28_Tarjeta_Propiedad_Trasera_foto"];

    if (fotoDelantera != "aprobada" || fotoTrasera != "aprobada") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes aprobar ambas fotos antes de aprobar el vehículo"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final faltantes = validarCamposVehiculo();

    if (faltantes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Faltan campos: ${faltantes.join(", ")}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hayErroresSeleccionados()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes quitar los errores antes de aprobar"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    /// ✅ APRUEBA SOLO SI TODO ESTÁ BIEN
    await FirebaseFirestore.instance
        .collection("Drivers")
        .doc(driverId)
        .collection("vehiculos")
        .doc(placa)
        .update({

      "estado_documentos": "aprobado",
      "errores": {},

      /// 🔥 NUEVO: APROBAR CADA FOTO
      "27_Tarjeta_Propiedad_Delantera_foto": "aprobada",
      "28_Tarjeta_Propiedad_Trasera_foto": "aprobada",
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Vehículo aprobado correctamente"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  Future<void> aprobarFoto(String driverId, String placa, String campoFoto) async {

    String campoEstado = "";

    if (campoFoto == "foto_tarjeta_propiedad_delantera") {
      campoEstado = "27_Tarjeta_Propiedad_Delantera_foto";
    } else if (campoFoto == "foto_tarjeta_propiedad_trasera") {
      campoEstado = "28_Tarjeta_Propiedad_Trasera_foto";
    }

    await FirebaseFirestore.instance
        .collection("Drivers")
        .doc(driverId)
        .collection("vehiculos")
        .doc(placa)
        .update({

      /// 🔥 aprobar SOLO esa foto
      campoEstado: "aprobada",

      /// 🔥 eliminar error solo de esa foto
      "errores.$campoFoto": FieldValue.delete(),

    });
    setState(() {
      errores.remove(campoFoto);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Foto aprobada correctamente"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool> puedeActivarseConductor(Driver driver, List vehiculos) async {

    /// 🔥 1. validar datos personales
    bool datosOk =
        driver.the29FotoPerfil == "aceptada" &&
            driver.the25CedulaDelanteraFoto == "aceptada" &&
            driver.the26CedulaTraseraFoto == "aceptada" &&
            driver.the05FechaExpedicionDocumento.isNotEmpty &&
            driver.the08FechaNacimiento.isNotEmpty &&
            driver.the09Genero.isNotEmpty &&
            driver.licenciaCategoria.isNotEmpty &&
            driver.licenciaVigencia.isNotEmpty;

    /// 🔥 2. validar vehículos
    bool tieneVehiculoAprobado = vehiculos.any((v) {
      return v["estado_documentos"] == "aprobado";
    });

    return datosOk && tieneVehiculoAprobado;
  }

  DateTime? _parseFecha(String? s) {
    if (s == null || s.isEmpty) return null;

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(s);
    } catch (_) {
      return null;
    }
  }



  Color _colorEstado(String estado) {
    switch (estado) {
      case "vencido":
        return Colors.red;
      case "porVencer":
        return Colors.orange;
      case "vigente":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget badgeVigencia({
    required String? fechaBd,
  }) {
    final fechaVence = vencimientoDiaAntesDesdeBD(fechaBd);
    final info = calcularEstadoVigencia(fechaVence);

    final color = _colorEstadoVigencia(info.estado);

    final fechaStr = fechaVence == null
        ? ""
        : DateFormat('dd/MM/yyyy').format(fechaVence);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        fechaStr.isEmpty
            ? textoEstado(info)
            : "${textoEstado(info)} · $fechaStr",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> validarEstadoConductor(String driverId) async {
    final vehiculosSnapshot = await FirebaseFirestore.instance
        .collection('Drivers')
        .doc(driverId)
        .collection('vehiculos')
        .get();

    bool tieneAprobado = vehiculosSnapshot.docs.any((doc) {
      final data = doc.data();
      return data["estado_documentos"] == "aprobado";
    });

    await FirebaseFirestore.instance
        .collection('Drivers')
        .doc(driverId)
        .update({
      "the00_is_active": tieneAprobado,
    });

    print("🔄 Conductor actualizado: activo = $tieneAprobado");
  }


}

enum VigenciaEstado { sinFecha, vencido, porVencer, vigente }

class VigenciaInfo {
  final VigenciaEstado estado;
  final int? diasRestantes;
  final DateTime? fechaVence;

  VigenciaInfo(this.estado, this.diasRestantes, this.fechaVence);
}

DateTime? parseFechaCO(String? s) {
  if (s == null) return null;
  final t = s.trim();
  if (t.isEmpty) return null;
  try {
    return DateFormat('dd/MM/yyyy').parseStrict(t);
  } catch (_) {
    return null;
  }
}

DateTime? vencimientoDiaAntesDesdeBD(String? fechaBd) {
  final f = parseFechaCO(fechaBd);
  if (f == null) return null;
  return DateTime(f.year, f.month, f.day).subtract(const Duration(days: 1));
}

VigenciaInfo calcularEstadoVigencia(DateTime? fechaVence, {int diasAlerta = 30}) {
  if (fechaVence == null) return VigenciaInfo(VigenciaEstado.sinFecha, null, null);

  final now = DateTime.now();
  final hoy = DateTime(now.year, now.month, now.day);
  final vence = DateTime(fechaVence.year, fechaVence.month, fechaVence.day);

  final diff = vence.difference(hoy).inDays;

  if (diff < 0) return VigenciaInfo(VigenciaEstado.vencido, diff, fechaVence);
  if (diff <= diasAlerta) return VigenciaInfo(VigenciaEstado.porVencer, diff, fechaVence);
  return VigenciaInfo(VigenciaEstado.vigente, diff, fechaVence);
}

String textoEstado(VigenciaInfo info) {
  switch (info.estado) {
    case VigenciaEstado.sinFecha:
      return "Sin fecha";
    case VigenciaEstado.vencido:
      return "Vencido (${info.diasRestantes!.abs()} días)";
    case VigenciaEstado.porVencer:
      return "Por vencer (${info.diasRestantes} días)";
    case VigenciaEstado.vigente:
      return "Vigente";
  }
}

Color _colorEstadoVigencia(VigenciaEstado e) {
  switch (e) {
    case VigenciaEstado.vencido:
      return Colors.red;
    case VigenciaEstado.porVencer:
      return Colors.orange;
    case VigenciaEstado.vigente:
      return Colors.green;
    case VigenciaEstado.sinFecha:
      return Colors.grey;
  }
}