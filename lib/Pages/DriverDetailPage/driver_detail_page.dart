import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/main_layout.dart';
import '../../models/conductor_model.dart';
import '../../models/operador_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';


class DriverDetailPage extends StatefulWidget {
  Driver driver;
  DriverDetailPage({Key? key, required this.driver}) : super(key: key);


  @override
  State<DriverDetailPage> createState() => _DriverDetailPageState();
}


class _DriverDetailPageState extends State<DriverDetailPage> {
  final DriverProvider _driverProvider = DriverProvider();
  bool isDocumentodeidentidadVisible = false;
  bool isDocumentosVehiculoVisible = false;
  bool isSoatTecnoVisible = false;
  bool isComunicacionNotificacionesVisible = false;
  bool isRecargaVisible = false;
  bool isLicenciaisible = false;
  String? selectedTipoDocumento;
  String? selectedGenero;
  String? selectedMarca;
  String? selectedModelo;
  String? selectedColor;
  String? selectedTipoServicio;
  String? selectedTipoVehiculo;
  String? selectedcategoriaLicencia;
  int nuevaRecarga = 0;
  String? rol;
  String? nameOperador;
  String? apellidosOperador;
  String? phoneNumber;
  double _progress = 0;
  late InAppWebViewController inAppWebViewController;
  bool isRecargasvisible = false;
  double averageRating = 0.0;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  List<Map<String, dynamic>> vehiculos = [];



  Operador? operador;
  final OperadorProvider _operadorProvider = OperadorProvider();
  final MyAuthProvider _authProvider = MyAuthProvider();

  @override
  void initState() {
    super.initState();

    selectedTipoDocumento = widget.driver.the04TipoDocumento;
    selectedGenero = widget.driver.the09Genero;
    selectedcategoriaLicencia = widget.driver.licenciaCategoria;
    _initAllControllers();

    getClientRatings();
    getOperadorInfo();

    getVehiculos();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  //selector de fecha reutilizable

  Widget _buildDateField({
    required String label,
    required String key,
    required String initialValue,
  }) {
    final controller = _controllers[key] ??= TextEditingController(text: initialValue);
    final focusNode = _focusNodes[key] ??= FocusNode();

    // Parser para tu formato dd/MM/yyyy
    DateTime? _parse(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(t);
      } catch (_) {
        return null;
      }
    }

    Future<void> _pickDate() async {
      // Cierra teclado si lo hubiera
      FocusScope.of(context).unfocus();

      final now = DateTime.now();
      final current = _parse(controller.text);

      final picked = await showDatePicker(
        context: context,
        initialDate: current ?? now,
        firstDate: DateTime(1900),
        lastDate: DateTime(now.year + 30),
        helpText: label,
        locale: const Locale('es', 'CO'),
      );

      if (picked == null) return;

      final formatted = DateFormat('dd/MM/yyyy').format(picked);

      // ✅ 1) actualiza el texto (para que no se borre)
      controller.text = formatted;

      // ✅ 2) guarda en Firestore
      await _saveField(key, formatted);

      // ✅ 3) sincroniza el objeto local driver
      _updateDriverLocal(key, formatted);

      if (mounted) setState(() {});
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: true,              // ✅ no editable manual
        onTap: _pickDate,            // ✅ abre calendario
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickDate,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Future<void> getVehiculos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Drivers')
        .doc(widget.driver.id)
        .collection('vehiculos')
        .get();

    vehiculos = snapshot.docs.map((doc) {
      final data = doc.data();
      data["id"] = doc.id;
      return data;
    }).toList();

    if (mounted) setState(() {});
  }

  void _initController(String key, String? value) {
    _controllers[key] = TextEditingController(text: value ?? '');
    _focusNodes[key] = FocusNode();
  }

  void _initAllControllers() {
    _initController("01_Nombres", widget.driver.the01Nombres);
    _initController("02_Apellidos", widget.driver.the02Apellidos);
    _initController("03_Numero_Documento", widget.driver.the03NumeroDocumento);
    _initController("05_Fecha_Expedicion_Documento", widget.driver.the05FechaExpedicionDocumento);
    _initController("08_Fecha_Nacimiento", widget.driver.the08FechaNacimiento);



    _initController("licencia_vigencia", widget.driver.licenciaVigencia);

    // Enteros
    _initController("34_Nueva_Recarga", (widget.driver.the34NuevaRecarga ?? 0).toString());
  }


  Color getStatusColor() {
    if (widget.driver.verificacionStatus == "registrado"
    ) {
      return Colors.blueGrey;
    }
    else if (widget.driver.verificacionStatus == "foto_tomada") {
      return Colors.amber;
    }
    else if (widget.driver.verificacionStatus == 'Procesando') {
      return Colors.blueAccent;
    }
    else if (widget.driver.verificacionStatus == 'corregida') {
      return Colors.purple;
    }

    else if (widget.driver.verificacionStatus == 'activado') {
      return Colors.green;
    }
    else if (widget.driver.verificacionStatus == 'bloqueado') {
      return Colors.red.shade900;
    }
    else if (widget.driver.verificacionStatus == 'bloqueo_AJ') {
      return Colors.deepOrange;
    }
    else if (widget.driver.verificacionStatus == '') {
      return Colors.brown.shade900;
    }
    else {
      return Colors.grey;
    }
  }

  Color getStatusColorFotos(String fotoStatus) {
    switch (fotoStatus) {
      case "rechazada":
        return Colors.red;
      case "corregida":
        return Colors.purple;
      case "aceptada":
        return Colors.green;
      default:
        return Colors.grey;  // Por si acaso el estado es diferente o nulo
    }
  }

  // Método para convertir booleanos en "SI" o "NO"
  String boolToYesNo(bool value) {
    return value ? 'SI' : 'NO';
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle:  obtenerRolParaTitulo(),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(7),
        child: Container(
          margin: const EdgeInsets.only(bottom: 100),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _encabezadoSeccion(),
                    const Divider(),
                    _seccionDatosGenerales(),
                    const Divider(),
                    _seccionDocumentosdeIdentidad(),
                    const Divider(),
                    _seccionLicencia(),
                    const Divider(),
                    _seccionVehiculos(),
                    const SizedBox(height: 50,)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionVehiculos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Vehículos del conductor"),
        const SizedBox(height: 10),

        if (vehiculos.isEmpty)
          const Text("Este conductor no tiene vehículos registrados"),

        ...vehiculos.map((vehiculo) {
          final isActivo = vehiculo["id"] == widget.driver.vehiculoActivoId;

          Color colorEstado;
          switch (vehiculo["estado_documentos"]) {
            case "aprobado":
              colorEstado = Colors.green;
              break;
            case "rechazado":
              colorEstado = Colors.red;
              break;
            default:
              colorEstado = Colors.orange;
          }

          return Card(
            color: isActivo ? Colors.green.withOpacity(0.08) : null,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

              title: Row(
                children: [
                  Text(
                    "Placa: ${vehiculo["18_Placa"] ?? ""}",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),

                  if (isActivo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "ACTIVO",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text("Marca: ${vehiculo["15_Marca"] ?? ""}"),
                  Text("Modelo: ${vehiculo["17_Modelo"] ?? ""}"),
                ],
              ),

                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    /// 🔍 VER DETALLE
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        minimumSize: const Size(0, 30),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          "detalle_vehiculo_page",
                          arguments: {
                            ...vehiculo,
                            "driverId": widget.driver.id, // 🔥 IMPORTANTE
                          },
                        );
                      },
                      child: const Text("Ver", style: TextStyle(fontSize: 12)),
                    ),

                    const SizedBox(height: 6),
                  ],
                )
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _activarVehiculo(String vehiculoId, String placa) async {
    try {
      await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(widget.driver.id)
          .update({
        "vehiculoActivoId": vehiculoId,
        "placaActiva": placa,
      });

      // 🔥 Actualizamos en memoria para refrescar UI
      setState(() {
        widget.driver.vehiculoActivoId = vehiculoId;
        widget.driver.placaActiva = placa;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vehículo activado correctamente"),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al activar vehículo: $e"),
        ),
      );
    }
  }

  Widget _encabezadoSeccion() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        // Define el tamaño de la letra según el ancho de la pantalla
        double fontSize = screenWidth < 600 ? 12.0 : 16.0;

        // Define si es móvil o no
        bool isMobile = screenWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.driver.id,
              style: TextStyle(fontSize: fontSize),
            ),
            isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text('${widget.driver.the01Nombres} ${widget.driver.the02Apellidos}', style: const TextStyle( fontSize: 18, fontWeight: FontWeight.bold), ),
                    Text('Conductor desde: ${widget.driver.the10FechaRegistro}',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ],
                ),

                Divider(),
                _buildInfoEstadoConductor('Conectado:', widget.driver.the39EstaConectado ?? false, fontSize),
                _buildInfoEstadoConductor('Trabajando:', widget.driver.the00_is_working ?? false, fontSize),
                _buildInfoRowHorizontal('Saldo Recarga', _formatearNumero(widget.driver.the32SaldoRecarga)),
                const SizedBox(height: 20),
                Container(
                  alignment: Alignment.center,
                    width: 200,
                    child: _buildVerificationStatus(fontSize)),

              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.driver.the01Nombres} ${widget.driver.the02Apellidos}', style: const TextStyle( fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Conductor desde: ${widget.driver.the10FechaRegistro}',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ],
                ),

                Column(
                  children: [
                    _buildInfoEstadoConductor('Conectado:', widget.driver.the39EstaConectado ?? false, fontSize),
                    _buildInfoEstadoConductor('Trabajando:', widget.driver.the00_is_working ?? false, fontSize),
                  ],
                ),
                _buildInfoRow('Saldo Recarga', _formatearNumero(widget.driver.the32SaldoRecarga)),
                _buildVerificationStatus(fontSize),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _seccionDatosGenerales() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        // Define el tamaño de la letra según el ancho de la pantalla
        double fontSize = screenWidth < 600 ? 12.0 : 16.0;
        // Define si es móvil o no
        bool isMobile = screenWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Datos Generales'),
                botonesComunicacion(context)

              ],
            ),

            isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoColumns(),
                const SizedBox(height: 25),
                _buildActionButtonRow(context),
                const SizedBox(height: 25),
                Row(
                  children: [
                    _buildPhotoStack(),
                    const SizedBox(width: 25),
                    _buildButtonRowAceptarRechazarFotoPerfil(context),
                  ],
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _buildPhotoStack(),
                    const SizedBox(height: 30),
                    _buildButtonRowAceptarRechazarFotoPerfil(context),
                  ],
                ),
                const SizedBox(width: 50),
                _buildInfoColumns(),
                const SizedBox(width: 150),
                _buildActionButtonColumn(context),
              ],
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _seccionDocumentosdeIdentidad(){
    return LayoutBuilder(
      builder: (context, constraints){
        double screenWidth = constraints.maxWidth;
        // Define el tamaño de la letra según el ancho de la pantalla
        double fontSize = screenWidth < 600 ? 12.0 : 16.0;

        // Define si es móvil o no
        bool isMobile = screenWidth < 600;
        return Column(
          children: [
            isMobile ?
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            isDocumentodeidentidadVisible = !isDocumentodeidentidadVisible;
                          });
                        },
                        child: _buildSectionTitle('Documento de identidad')),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          isDocumentodeidentidadVisible = !isDocumentodeidentidadVisible;
                        });
                      },
                      icon: Icon(
                        isDocumentodeidentidadVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                Visibility(
                  visible: isDocumentodeidentidadVisible,
                  child: Column(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,  // Permitir que los elementos dentro del Stack se dibujen fuera de sus límites
                                  children: [
                                    _buildDocumentPhoto("Cédula parte delantera", widget.driver.fotoCedulaDelantera),
                                    Positioned(
                                      top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
                                      right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: getStatusColorFotos(widget.driver.the25CedulaDelanteraFoto),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                _buildTextField(widget.driver.the01Nombres, 'Nombres', "01_Nombres"),
                                _buildTextField(widget.driver.the02Apellidos, 'Apellidos', "02_Apellidos"),
                                _dropTipoDocumento (),
                                _buildTextField(widget.driver.the03NumeroDocumento, 'Número de Documento', "03_Numero_Documento"),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationFotoCedulaDelantera(context, "¿Aceptar la foto del documento de identidad en su parte delantera?", "aceptada");
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.check_circle, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationFotoCedulaDelantera(context, "¿Está seguro de rechazar la foto del documento en su parte delantera?", "rechazada");
                                          _saveField("Verificacion_Status", "rechazada");

                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.block, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushNamed(context, "antecedentes_page");

                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.add_chart_sharp, color: Colors.white, size: 30), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: ElevatedButton(
                                        onPressed: () {

                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.person_off, color: Colors.white, size: 30), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),
                          Divider(),// Espacio entre columnas
                          const SizedBox(height: 20),
                          Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,  // Permitir que los elementos dentro del Stack se dibujen fuera de sus límites
                                  children: [
                                    _buildDocumentPhoto("Cédula parte trasera", widget.driver.fotoCedulaTrasera),
                                    Positioned(
                                      top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
                                      right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: getStatusColorFotos(widget.driver.the26CedulaTraseraFoto),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                _buildDateField(
                                  label: 'Fecha de expedición',
                                  key: '05_Fecha_Expedicion_Documento',
                                  initialValue: widget.driver.the05FechaExpedicionDocumento,
                                ),
                                _buildDateField(
                                  label: 'Fecha de nacimiento',
                                  key: '08_Fecha_Nacimiento',
                                  initialValue: widget.driver.the08FechaNacimiento,
                                ),
                                _dropGenero(),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationFotoCedulaTrasera(context, "¿Aceptar la foto del documento de identidad en su parte trasera?", "aceptada");
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.check_circle, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationFotoCedulaTrasera(context, "¿Está seguro de rechazar la foto del documento en su parte trasera?", "rechazada");
                                          _saveField("Verificacion_Status", "rechazada");

                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.block, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                        ],
                      ),

                    ],
                  ),
                ),
              ],
            ) : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            isDocumentodeidentidadVisible = !isDocumentodeidentidadVisible;
                          });
                        },
                        child: _buildSectionTitle('Documento de identidad')),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          isDocumentodeidentidadVisible = !isDocumentodeidentidadVisible;
                        });
                      },
                      icon: Icon(
                        isDocumentodeidentidadVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                Visibility(
                  visible: isDocumentodeidentidadVisible,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,  // Permitir que los elementos dentro del Stack se dibujen fuera de sus límites
                                  children: [
                                    _buildDocumentPhoto("Cédula parte delantera", widget.driver.fotoCedulaDelantera),
                                    Positioned(
                                      top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
                                      right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: getStatusColorFotos(widget.driver.the25CedulaDelanteraFoto),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                _buildTextField(widget.driver.the01Nombres, 'Nombres', "01_Nombres"),
                                _buildTextField(widget.driver.the02Apellidos, 'Apellidos', "02_Apellidos"),
                                _dropTipoDocumento (),
                                _buildTextField(widget.driver.the03NumeroDocumento, 'Número de Documento', "03_Numero_Documento"),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationFotoCedulaDelantera(context, "¿Aceptar la foto del documento de identidad en su parte delantera?", "aceptada");
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.check_circle, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationFotoCedulaDelantera(context, "¿Está seguro de rechazar la foto del documento en su parte delantera?", "rechazada");
                                          _saveField("Verificacion_Status", "rechazada");

                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.block, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20), // Espacio entre columnas
                          Expanded(
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,  // Permitir que los elementos dentro del Stack se dibujen fuera de sus límites
                                  children: [
                                    _buildDocumentPhoto("Cédula parte trasera", widget.driver.fotoCedulaTrasera),
                                    Positioned(
                                      top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
                                      right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: getStatusColorFotos(widget.driver.the26CedulaTraseraFoto),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                _buildDateField(
                                  label: 'Fecha de expedición',
                                  key: '05_Fecha_Expedicion_Documento',
                                  initialValue: widget.driver.the05FechaExpedicionDocumento,
                                ),
                                _buildDateField(
                                  label: 'Fecha de nacimiento',
                                  key: '08_Fecha_Nacimiento',
                                  initialValue: widget.driver.the08FechaNacimiento,
                                ),

                                _dropGenero(),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationFotoCedulaTrasera(context, "¿Aceptar la foto del documento de identidad en su parte trasera?", "aceptada");
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.check_circle, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationFotoCedulaTrasera(context, "¿Está seguro de rechazar la foto del documento en su parte trasera?", "rechazada");
                                          _saveField("Verificacion_Status", "rechazada");

                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.block, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 20),
                            height: 50, // Altura del botón
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                const url = 'https://antecedentes.policia.gov.co:7005/WebJudicial/';
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 20), backgroundColor: primary, // Color de fondo del botón
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              icon: const Icon(Icons.add_chart_sharp, color: Colors.white), // Icono de Correo
                              label: const Text('Antecedentes', style: TextStyle( color: blanco)),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            height: 50, // Altura del botón
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showConfirmationBloqueoAJ(context, "¿Está seguro de bloquear el conductor por AJ?", "bloqueo_AJ");

                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20), backgroundColor: Colors.redAccent, // Color de fondo del botón
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              icon: const Icon(Icons.cancel, color: Colors.white), // Icono de Correo
                              label: const Text('Bloqueo AJ', style: TextStyle( color: blanco)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }
    );
  }





  Widget _seccionLicencia() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => isLicenciaisible = !isLicenciaisible),
                  child: _buildSectionTitle('Licencia de conducción'),
                ),
                IconButton(
                  onPressed: () => setState(() => isLicenciaisible = !isLicenciaisible),
                  icon: Icon(
                    isLicenciaisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 30,
                  ),
                ),
              ],
            ),

            Visibility(
              visible: isLicenciaisible,
              child: isMobile
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dropCategoriaLicencia(),

                  // ✅ FECHA + BADGE
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Vigencia Licencia (fecha BD)',
                          key: 'licencia_vigencia',
                          initialValue: widget.driver.licenciaVigencia,
                        ),
                      ),
                      const SizedBox(width: 10),
                      badgeVigencia(
                        fechaBd: widget.driver.licenciaVigencia,
                        calcularVence: vencimientoDiaAntesDesdeBD,
                        diasAlerta: 30,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        const url = 'https://portalpublico.runt.gov.co/#/consulta-ciudadano-documento/consulta/consulta-ciudadano-documento';
                        if (await canLaunch(url)) {
                          await launch(url);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      icon: const Icon(Icons.add_chart_sharp, color: Colors.white),
                      label: const Text('Abrir página RUNT Conductores', style: TextStyle(color: blanco)),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Columna izquierda (campos)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dropCategoriaLicencia(),

                        // ✅ FECHA + BADGE (en escritorio también)
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                label: 'Vigencia Licencia (fecha BD)',
                                key: 'licencia_vigencia',
                                initialValue: widget.driver.licenciaVigencia,
                              ),
                            ),
                            const SizedBox(width: 10),
                            badgeVigencia(
                              fechaBd: widget.driver.licenciaVigencia,
                              calcularVence: vencimientoDiaAntesDesdeBD,
                              diasAlerta: 30,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  const SizedBox(width: 60),

                  // ✅ Botón derecha
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          const url = 'https://portalpublico.runt.gov.co/#/consulta-ciudadano-documento/consulta/consulta-ciudadano-documento';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        icon: const Icon(Icons.add_chart_sharp, color: Colors.white),
                        label: const Text('Abrir página RUNT Conductores', style: TextStyle(color: blanco)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _seccionComunicacionNotificaciones(){
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        // Define el tamaño de la letra según el ancho de la pantalla
        double fontSize = screenWidth < 600 ? 12.0 : 16.0;

        // Define si es móvil o no
        bool isMobile = screenWidth < 600;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                      onTap: (){
                        setState(() {
                          isComunicacionNotificacionesVisible = !isComunicacionNotificacionesVisible;
                        });
                      },
                      child: _buildSectionTitle('Activación y notificaciones')),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isComunicacionNotificacionesVisible = !isComunicacionNotificacionesVisible;
                      });
                    },
                    icon: Icon(
                      isComunicacionNotificacionesVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 30,
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: isComunicacionNotificacionesVisible,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Lógica para informar activación por WhatsApp
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  icon: const Icon(Icons.message, color: Colors.white, size: 14,),
                                  label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 30),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Lógica para informar activación por Mail
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  icon: const Icon(Icons.email, color: Colors.white, size: 14,),
                                  label: const Text('EMail', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                          const TextField(
                            decoration: InputDecoration(
                              labelText: 'Mensaje de Notificación',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Lógica para enviar notificación directa
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              icon: const Icon(Icons.send, color: Colors.white, size: 14,),
                              label: const Text('Notificación', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                  ],
                ),
              ),
            ],
          );

      },
    );
  }


  void getOperadorInfo() async {
    var user = _authProvider.getUser();
    if (user != null) {
      operador = await _operadorProvider.getById(user.uid);
      if (operador != null) {
        rol = operador?.the20Rol;
        nameOperador =operador?.the01Nombres;
        apellidosOperador= operador?.the02Apellidos;
        if(rol == "Master" || rol == "Recarga Carros"){
          setState(() {
            isRecargasvisible = true;
          });
        }
      }
    }
    print('Datos del operador ***************************************** $rol');
  }

  Widget botonesComunicacion (context){
    bool isMobile = !kIsWeb;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            if(isMobile){
              _openWhatsApp(context);
            }
            _openWhatsAppWeb(context);
          },
          child: Image.asset(
            'assets/icono_whatsapp.png', // Ruta de la imagen de WhatsApp
            width: 30,
            height: 30,
          ),
        ),
        const SizedBox(width: 20), // Espacio entre la imagen y el icono
        GestureDetector(
          onTap: () {
            makePhoneCall(widget.driver.the07Celular);
          },
          child: const Icon(
            Icons.phone,
            color: Colors.black, // Color del icono de llamada
            size: 30,
          ),
        ),
        Divider()
      ],
    );
  }

  Widget _buildButtonRowAceptarRechazarFotoPerfil(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 30,
          width: 30,
          child: ElevatedButton(
            onPressed: () {
              _showConfirmationFotoPerfil(context, "¿Aceptar la foto de perfil?", "aceptada");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
            ),
            child: const Center(
              child: Icon(Icons.check_circle, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
            ),
          ),
        ),
        const SizedBox(width: 35),
        SizedBox(
          height: 30,
          width: 30,
          child: ElevatedButton(
            onPressed: () {
              _showConfirmationFotoPerfil(context, "¿Está seguro de rechazar la foto de perfil?", "rechazada");
              _saveField("Verificacion_Status", "rechazada");

            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.zero, // Ajuste para eliminar cualquier padding interno
            ),
            child: const Center(
              child: Icon(Icons.block, color: Colors.white, size: 20), // Ajusta el tamaño del icono según sea necesario
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoStack() {
    return Stack(
      clipBehavior: Clip.none,  // Permitir que los elementos dentro del Stack se dibujen fuera de sus límites
      children: [
        _buildPerfilPhoto(widget.driver.image),
        Positioned(
          top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
          right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: getStatusColorFotos(widget.driver.the29FotoPerfil),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildInfoColumns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRowHorizontal('Fecha activación:   ', widget.driver.the12FechaActivacion),
        _buildInfoRowHorizontal('Activador:   ', widget.driver.the13NombreActivador),
        _buildInfoRowHorizontal('Email:   ', widget.driver.the06Email),
        _buildInfoRowHorizontal('Celular:   ', widget.driver.the07Celular),
        _buildInfoRowHorizontalBold('Viajes:   ', widget.driver.the30NumeroViajes.toString()),
        _buildInfoRowHorizontalIconoEstrella('Calificación:   ', averageRating.toStringAsFixed(1)),
        _buildInfoRowHorizontalIconocancel('Cancelaciones:   ', widget.driver.the40NumeroCancelaciones.toString()),
      ],
    );
  }

  void getClientRatings() async {
    final driverId = widget.driver.id;  // Obtienes el ID del conductor

    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(driverId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        int ratingCount = ratingsSnapshot.docs.length;

        for (var doc in ratingsSnapshot.docs) {
          totalRating += doc['calificacion'];  // Asegúrate de que 'calificacion' esté en cada documento de la subcolección
        }

        // Calcular la calificación promedio
        setState(() {
          averageRating = totalRating / ratingCount;  // Guardar la calificación promedio
        });
      } else {
        setState(() {
          averageRating = 0.0;  // Si no hay calificaciones, asignar 0
        });
      }
    } catch (e) {
      setState(() {
        averageRating = 0.0;  // Si ocurre algún error, asignar 0
      });
      print("Error obteniendo calificaciones: $e");
    }
  }

  Widget _buildActionButtonColumn(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40, // Altura del botón
          child: ElevatedButton.icon(
            onPressed: () {
              _showConfirmationDialogBloquearusuario(context, "¿Está seguro de bloquear este conductor?", true);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.red, // Color de fondo del botón
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontSize: 16),
            ),
            icon: const Icon(Icons.block, color: Colors.white), // Icono de Correo
            label: const Text('BLOQUEAR', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 40, // Altura del botón
          child: ElevatedButton.icon(
            onPressed: () {
              _showConfirmationDialogActivarusuario(context, "¿Está seguro de activar este conductor?", false);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.green, // Color de fondo del botón
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontSize: 16),
            ),
            icon: const Icon(Icons.check_circle, color: Colors.white), // Icono de Correo
            label: const Text('ACTIVAR', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonRow(BuildContext context) {
    return Row(
      mainAxisAlignment:MainAxisAlignment.spaceEvenly ,
      children: [
        SizedBox(
          height: 40, // Altura del botón
          child: ElevatedButton.icon(
            onPressed: () {
              _showConfirmationDialogBloquearusuario(context, "¿Está seguro de bloquear este conductor?", true);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.red, // Color de fondo del botón
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontSize: 16),
            ),
            icon: const Icon(Icons.block, color: Colors.white), // Icono de Correo
            label: const Text('BLOQUEAR', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 40, // Altura del botón
          child: ElevatedButton.icon(
            onPressed: () {
              _showConfirmationDialogActivarusuario(context, "¿Está seguro de activar este conductor?", false);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.green, // Color de fondo del botón
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontSize: 16),
            ),
            icon: const Icon(Icons.check_circle, color: Colors.white), // Icono de Correo
            label: const Text('ACTIVAR', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _dropTipoDocumento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de Documento', style: TextStyle(fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedTipoDocumento,
                items: const [
                  DropdownMenuItem(value: "", child: Text("")),
                  DropdownMenuItem(
                    value: "Cédula de Ciudadanía",
                    child: Text("Cédula de Ciudadanía"),
                  ),
                  DropdownMenuItem(
                    value: "Cédula de extranjería",
                    child: Text("Cédula de extranjería"),
                  ),
                  DropdownMenuItem(value: "Pasaporte", child: Text("Pasaporte")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedTipoDocumento = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final valueToSave = (selectedTipoDocumento ?? "").trim();

                await _saveField("04_Tipo_Documento", valueToSave);

                setState(() {
                  widget.driver.the04TipoDocumento = valueToSave;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  Widget _dropGenero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Género', style: TextStyle(fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedGenero,
                items: const [
                  DropdownMenuItem(value: "", child: Text("")),
                  DropdownMenuItem(value: "Masculino", child: Text("Masculino")),
                  DropdownMenuItem(value: "Femenino", child: Text("Femenino")),
                  DropdownMenuItem(value: "Otro", child: Text("Otro")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGenero = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final valueToSave = (selectedGenero ?? "").trim();

                await _saveField("09_Genero", valueToSave);

                setState(() {
                  widget.driver.the09Genero = valueToSave;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }




  Widget _dropCategoriaLicencia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categoría', style: TextStyle(fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedcategoriaLicencia,
                items: const [
                  DropdownMenuItem(value: "", child: Text("")),
                  DropdownMenuItem(value: "A1", child: Text("A1")),
                  DropdownMenuItem(value: "A2", child: Text("A2")),
                  DropdownMenuItem(value: "B1", child: Text("B1")),
                  DropdownMenuItem(value: "B2", child: Text("B2")),
                  DropdownMenuItem(value: "B3", child: Text("B3")),
                  DropdownMenuItem(value: "C1", child: Text("C1")),
                  DropdownMenuItem(value: "C2", child: Text("C2")),
                  DropdownMenuItem(value: "C3", child: Text("C3")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedcategoriaLicencia = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final valueToSave = (selectedcategoriaLicencia ?? "").trim();

                await _saveField("licencia_categoria", valueToSave);

                setState(() {
                  widget.driver.licenciaCategoria = valueToSave;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  //// widget para textedit strings////////
  // Widget _buildTextField(String initialValue, String label, String key) {
  //   TextEditingController controller = TextEditingController(text: initialValue);
  //   FocusNode focusNode = FocusNode();
  //   ValueNotifier<Color> borderColorNotifier = ValueNotifier<Color>(Colors.grey);
  //
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8.0),
  //     child: ValueListenableBuilder<Color>(
  //       valueListenable: borderColorNotifier,
  //       builder: (context, borderColor, child) {
  //         return TextField(
  //           controller: controller,
  //           focusNode: focusNode,
  //           decoration: InputDecoration(
  //             labelText: label,
  //             suffixIcon: IconButton(
  //               icon: Icon(Icons.save),
  //               onPressed: () {
  //                 _saveField(key, controller.text);
  //                 borderColorNotifier.value = Colors.grey; // Retornar al color inicial
  //                 focusNode.unfocus(); // Quitar el foco del TextField
  //               },
  //             ),
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(10),
  //               borderSide: BorderSide(color: borderColor),
  //             ),
  //             focusedBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(10),
  //               borderSide: BorderSide(color: borderColor),
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(10),
  //               borderSide: BorderSide(color: borderColor),
  //             ),
  //           ),
  //           onChanged: (text) {
  //             borderColorNotifier.value = Colors.red; // Cambiar a color rojo al modificar
  //           },
  //         );
  //       },
  //     ),
  //   );
  // } comentado emjora para no recrear los textfield

  Widget _buildTextField(String initialValue, String label, String key) {
    final controller = _controllers[key] ??= TextEditingController(text: initialValue);
    final focusNode = _focusNodes[key] ??= FocusNode();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
             _saveField(key, controller.text);

              // ✅ actualiza el modelo local para que la UI siempre refleje lo mismo
              _updateDriverLocal(key, controller.text);

              if (mounted) focusNode.unfocus();
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
  //new

  void _updateDriverLocal(String key, String value) {
    setState(() {
      switch (key) {
        case "01_Nombres":
          widget.driver.the01Nombres = value;
          break;
        case "02_Apellidos":
          widget.driver.the02Apellidos = value;
          break;
        case "03_Numero_Documento":
          widget.driver.the03NumeroDocumento = value;
          break;
        case "05_Fecha_Expedicion_Documento":
          widget.driver.the05FechaExpedicionDocumento = value;
          break;
        case "08_Fecha_Nacimiento":
          widget.driver.the08FechaNacimiento = value;
          break;

        case "licencia_vigencia":
          widget.driver.licenciaVigencia = value;
          break;
      }
    });
  }



  Widget _buildTextFieldEnteros(int initialValue, String label, String key) {
    TextEditingController controller = TextEditingController(text: initialValue.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              _saveFieldEnteros(key, controller.text);
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
  Future<void> activarConductorEnFirestore() async {
    final data = {
      "11_Esta_activado": true,
      "38_Esta_bloqueado": false,
      "Verificacion_Status": "activado",
      "13_Nombre_Activador":
      "${nameOperador ?? 'Nombre'} ${apellidosOperador ?? 'Apellido'}",
      "12_Fecha_Activacion":
      DateFormat("d 'de' MMMM/yyyy - HH:mm:ss", 'es_ES')
          .format(DateTime.now()),
    };

    try {
      await _driverProvider.update(data, widget.driver.id);

      if (!context.mounted) return;
      _showSnackBar(context, 'Conductor activado correctamente');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Error al activar conductor');
      rethrow;
    }
  }


  void activarUsuario(BuildContext context) {
    String message;
    bool canActivate = false; // Variable para determinar si se puede activar el usuario

    // Verificar si el conductor tiene el status "bloqueo_AJ"
    if (widget.driver.verificacionStatus == "bloqueo_AJ") {
      message = 'Este conductor no se puede activar debido a un bloqueo administrativo';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Activar Conductor'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar el diálogo
                },
              ),
            ],
          );
        },
      );
      return; // Salir de la función si el conductor está bloqueado
    }

    // Verificar si el conductor ya está activado
    if (widget.driver.the11EstaActivado == true) {
      message = 'El conductor ya se encuentra activado';
    } else {
      // Condiciones para determinar si se puede activar el usuario
      if (widget.driver.the29FotoPerfil == "aceptada" &&
          widget.driver.the25CedulaDelanteraFoto == "aceptada" &&
          widget.driver.the05FechaExpedicionDocumento.isNotEmpty &&
          widget.driver.the08FechaNacimiento.isNotEmpty &&
          widget.driver.the09Genero.isNotEmpty &&
          widget.driver.licenciaCategoria.isNotEmpty &&
          widget.driver.licenciaVigencia.isNotEmpty) {
        message = 'El conductor ya puede ser activado';
        canActivate = true;
      } else {
        message = 'Hay alguna verificación que no se ha hecho y evita activar al conductor';
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Activar Conductor'),
          content: Text(message),
          actions: <Widget>[
            if (canActivate)
              TextButton(
                child: const Text('Activar'),
                onPressed: () async {
                  Navigator.of(context).pop(); // cerrar diálogo primero

                  try {
                    await activarConductorEnFirestore();

                    setState(() {
                      widget.driver.the11EstaActivado = true;
                      widget.driver.the38EstaBloqueado = false;
                      widget.driver.verificacionStatus = "activado";
                    });

                    if (!kIsWeb) {
                      _openWhatsAppActivacion(context);
                    } else {
                      _openWhatsAppWebActivacion(context);
                    }
                  } catch (_) {
                    // El error ya se muestra en el SnackBar
                  }
                },
              ),
          ],
        );
      },
    );
  }


  void bloquearUsuario(BuildContext context) {
    String message;

    // Verificar si el usuario ya está bloqueado
    if (widget.driver.the38EstaBloqueado == true) {
      // Si ya está bloqueado, mostramos el mensaje y salimos
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bloquear Conductor'),
            content: const Text('El conductor ya se encuentra bloqueado'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar el diálogo
                },
              ),
            ],
          );
        },
      );
      return; // Salir del método si el conductor ya está bloqueado
    }

    // Verificar si el usuario tiene el status "bloqueo_AJ"
    if (widget.driver.verificacionStatus == "bloqueo_AJ") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bloquear Conductor'),
            content: const Text('Este conductor ya tiene un bloqueo administrativo'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar el diálogo
                },
              ),
            ],
          );
        },
      );
      return; // Salir del método si el conductor tiene un bloqueo administrativo
    }

    // Si el usuario no está bloqueado y no tiene bloqueo administrativo, procedemos a bloquearlo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bloquear Conductor'),
          content: const Text('¿Está seguro de bloquear al conductor?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Bloquear'),
              onPressed: () {
                _saveField("38_Esta_bloqueado", true); // Marcar como bloqueado
                _saveField("11_Esta_activado", false); // Marcar como no activado
                _saveField("Verificacion_Status", "bloqueado"); // Actualizar el estado

                setState(() {
                  widget.driver.the11EstaActivado = false;
                  widget.driver.the38EstaBloqueado = true;
                  widget.driver.verificacionStatus = "bloqueado";
                });
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
          ],
        );
      },
    );
  }

  String _formatearNumero(int valor) {
    final format = NumberFormat("#,###", "es_CO");
    return '\$ ${format.format(valor)}';
  }

  Future<int> _obtenerNuevaRecargaDesdeBaseDeDatos() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(widget.driver.id)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return data['34_Nueva_Recarga'] ?? 0; // Si el valor es nulo, devolver 0 por defecto
      } else {
        throw Exception("No se pudo obtener el valor de la recarga.");
      }
    } catch (error) {
      print('Error al obtener nueva recarga desde la base de datos: $error');
      throw error;
    }
  }

  void _showConfirmationDialogActivarusuario(BuildContext context, String message, bool isBloquear) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("No"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: const Text("Sí"),
              onPressed: () async {
                Navigator.of(context).pop(); // cerrar diálogo primero

                await activarConductorEnFirestore();

                setState(() {
                  widget.driver.the11EstaActivado = true;
                  widget.driver.the38EstaBloqueado = false;
                  widget.driver.verificacionStatus = "activado";
                });

                if (!kIsWeb) {
                  _openWhatsAppActivacion(context);
                } else {
                  _openWhatsAppWebActivacion(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialogBloquearusuario(BuildContext context, String message, bool isBloquear) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("No"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: const Text("Sí"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                bloquearUsuario(context); // Llama al método para activar el usuario

              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationFotoPerfil(BuildContext context, String message, String isBloquear) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("Sí"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _saveField("29_Foto_perfil", isBloquear);
                setState(() {
                  widget.driver.the29FotoPerfil = isBloquear;
                });// Llama al método para guardar el campo
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationFotoCedulaDelantera(BuildContext context, String message, String isBloquear) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[

            TextButton(
              child: const Text("Sí"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _saveField("25_Cedula_Delantera_foto", isBloquear); // Llama al método para guardar el campo
                setState(() {
                  widget.driver.the25CedulaDelanteraFoto = isBloquear;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationFotoCedulaTrasera(BuildContext context, String message, String isBloquear) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[

            TextButton(
              child: const Text("Sí"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _saveField("26_Cedula_Trasera_foto", isBloquear); // Llama al método para guardar el campo
                setState(() {
                  widget.driver.the26CedulaTraseraFoto = isBloquear;
                });
              },
            ),
          ],
        );
      },
    );
  }



  void _showConfirmationBloqueoAJ(BuildContext context, String message, String isBloquear) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[

            TextButton(
              child: Text("Sí"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _saveField("Verificacion_Status", isBloquear); // Llama al método para guardar el campo
                setState(() {
                  widget.driver.verificacionStatus= isBloquear;
                });
              },
            ),
          ],
        );
      },
    );
  }

  //// metodo para guardar los editfield enteros/////
  Future<void> _saveFieldEnteros(String key, String value) async {
    try {
      await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(widget.driver.id)
          .update({key: int.parse(value)});
      print('Campo guardado exitosamente con key: $key y valor: $value');
    } catch (error) {
      print('Error al guardar campo con key: $key y valor: $value. Error: $error');
      throw error;
    }
  }


  void _saveFieldBool(String key, dynamic value) async {
    print("Guardando campo con key '$key' y valor '$value'");

    bool boolValue = false;
    if (value is String) {
      boolValue = bool.fromEnvironment(value.toLowerCase());
    } else if (value is bool) {
      boolValue = value;
    } else {
      print("Error: El valor '$value' no puede ser convertido a bool.");
      return;
    }

    Map<String, dynamic> data = {
      key: boolValue,
    };

    try {
      await _driverProvider.update(data, widget.driver.id);
      if(context.mounted){
        _showSnackBar(context, 'Actualizacion exitosa');
      }

    } catch (error) {
      if(context.mounted){
        _showSnackBar(context, 'Error al actualizar el conductor: $error');
      }
    }
  }


  //// metodo para guardar los editfield strings/////
  // void _saveField(String key, dynamic value) async {
  //   print("Guardando campo con key '$key' y valor '$value'");
  //
  //   Map<String, String> data = {key: value,
  //   };
  //   try {
  //     await _driverProvider.update(data, widget.driver.id);
  //     if(context.mounted){
  //       _showSnackBar(context, 'Actualización exitosa');
  //     }
  //   } catch (error) {
  //     if(context.mounted){
  //       _showSnackBar(context, 'Error al actualizar el conductor: $error');
  //     }
  //   }
  // } comentado mejora

  Future<void> _saveField(String key, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(widget.driver.id)
          .update({key: value});

      if (context.mounted) {
        _showSnackBar(context, 'Actualización exitosa');
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, 'Error al actualizar: $error');
      }
    }
  }


  void _saveFieldFecha(String key, DateTime date) async {
    // Formatear la fecha como cadena
    String formattedDate = DateFormat("d 'de' MMMM/yyyy - HH:mm:ss", 'es_ES').format(date);

    print("Guardando campo con key '$key' y valor '$formattedDate'");

    Map<String, String> data = {
      key: formattedDate,
    };

    try {
      await _driverProvider.update(data, widget.driver.id);
      if (context.mounted) {
        _showSnackBar(context, 'Actualización exitosa');
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, 'Error al actualizar el conductor: $error');
      }
    }
  }


  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String obtenerRolParaTitulo() {
    String rol = widget.driver.rol;
    if (rol == "moto") {
      return 'Motociclista: ${widget.driver.the01Nombres} ${widget.driver.the02Apellidos}';
    } else {
      return 'Conductor: ${widget.driver.the01Nombres} ${widget.driver.the02Apellidos}';
    }
  }


  Widget _buildTextFieldRecarga(int initialValue, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: TextEditingController(text: initialValue.toString()),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              // Implementar lógica de guardado aquí
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStatus(double fontSize) {
    Color statusColor = getStatusColor();
    String statusText = '';

    if (widget.driver.verificacionStatus == "registrado") {
      statusText = 'Registrado';
    } else if (widget.driver.verificacionStatus == "foto_tomada") {
      statusText = 'Fotos faltantes';
    } else if (widget.driver.verificacionStatus == 'Procesando') {
      statusText = 'Procesando';
    }
    else if (widget.driver.verificacionStatus == 'corregida') {
      statusText = 'Corregida';
    }
    else if (widget.driver.verificacionStatus == 'activado') {
      statusText = 'Activado';
    }
    else if (widget.driver.verificacionStatus == 'bloqueado') {
      statusText = 'Bloqueado';
    }else if (widget.driver.verificacionStatus == 'bloqueo_AJ') {
      statusText = 'BloqueoAJ';
    }

    else {
      statusText = 'En Espera';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: blanco,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor, width: 2)
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: const TextStyle(
              color: negro,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildInfoRowHorizontal(String label, String value) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 10)),
        ],
      );
  }

  Widget _buildInfoRowHorizontalBold(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoRowHorizontalIconoEstrella(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4), // Espacio entre el valor y el icono
            const Icon(
              Icons.star,
              size: 16,
              color: Colors.amber, // Puedes ajustar el color según tu preferencia
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRowHorizontalIconocancel(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4), // Espacio entre el valor y el icono
            const Icon(
              Icons.cancel,
              size: 16,
              color: Colors.redAccent, // Puedes ajustar el color según tu preferencia
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoEstadoConductor(String label, bool value, double fontSize) {
    return  Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize),
          ),
          const SizedBox(width: 3),
          Text(
            boolToYesNo(value), // Utilizamos la función de conversión
            style:TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
        ],
      );
  }

  Widget _buildDocumentPhotoStatus(String label, bool hasPhoto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Icon(
            hasPhoto ? Icons.check_circle : Icons.cancel,
            color: hasPhoto ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPhoto(String title, String? imageUrl) {
    bool isZoomed = false;

    return Column(
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          StatefulBuilder(
            builder: (context, setState) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    isZoomed = !isZoomed;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isZoomed ? 400 : 150,
                  height: isZoomed ? 320 : 100,
                  child: InteractiveViewer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(imageUrl),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        else
          const Icon(
            Icons.image,
            size: 100,
          ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPerfilPhoto(String? photoUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180, // Ajusta el tamaño cuadrado aquí
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: photoUrl != null
                  ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 50, // Ajusta el tamaño del ícono aquí
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Foto no disponible',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              )
                  : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 50, // Ajusta el tamaño del ícono aquí
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Foto no disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(BuildContext context) async {
    String phoneNumber = widget.driver.the07Celular;
    String? name = widget.driver.the01Nombres;
    String message = 'Hola $name, mi nombre es $nameOperador del equipo de asistencia de Metax.';
    final whatsappLink = Uri.parse('whatsapp://send?phone=+57$phoneNumber&text=$message');
    try {
      await launchUrl(whatsappLink);
    } catch (e) {
      showNoWhatsAppInstalledDialog(context);
    }
  }


  void _openWhatsAppActivacion(BuildContext context) async {
    String phoneNumber = widget.driver.the07Celular;
    String? driverName = widget.driver.the01Nombres;
    String message = '''Hola *$driverName*,

Soy $nameOperador del grupo de soporte de *Metax* y me complace informarte que tu cuenta de *Conductor* ya está activada.

¡Ingresa ahora mismo a tu aplicación. *¡Empieza a recibir servicios!*

Si tienes alguna duda, no dudes en contactarnos.

Saludos cordiales,
El equipo de Metax''';


    final whatsappLink = Uri.parse('whatsapp://send?phone=+57$phoneNumber&text=$message');
    try {
      await launchUrl(whatsappLink);
    } catch (e) {
      showNoWhatsAppInstalledDialog(context);
    }
  }


  void _openWhatsAppWeb(BuildContext context) async {
    String phoneNumber = widget.driver.the07Celular;
    String? driverName = widget.driver.the01Nombres;
    String message = 'Hola $driverName, mi nombre es $nameOperador del equipo de asistencia de Metax.';
    sendWhatsAppWeb(phone: phoneNumber, text: message);
  }

  void _openWhatsAppWebActivacion(BuildContext context) async {
    String phoneNumber = widget.driver.the07Celular;
    String? driverName = widget.driver.the01Nombres;

    String message = '''Hola *$driverName*,

Soy $nameOperador del grupo de soporte de *Metax* y me complace informarte que tu cuenta de *Conductor* ya está activada.

¡Ingresa ahora mismo a tu aplicación. *¡Empieza a recibir servicios!*

Si tienes alguna duda, no dudes en contactarnos.

Saludos cordiales,
El equipo de Metax''';

    // Asegurarse de que el número de teléfono tiene el código de país
    final String fullPhoneNumber = "57$phoneNumber".replaceAll(RegExp(r'\s+'), '');

    // Codificar el mensaje para la URL utilizando encodeFull, que maneja caracteres especiales
    final String encodedMessage = Uri.encodeFull(message);

    // Crear la URL con el número de teléfono y el mensaje codificado
    final Uri whatsappWebUri = Uri.parse("https://wa.me/$fullPhoneNumber?text=$encodedMessage");

    // Intentar abrir WhatsApp Web con la URL generada
    if (!await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se puede enviar un mensaje a $fullPhoneNumber');
    }
  }

////metodo para abrir whatsapp web
  Future<void> sendWhatsAppWeb({required String phone, required String text}) async {
    const String countryCode = "57"; // Código de país para Colombia
    final String fullPhoneNumber = "$countryCode$phone".replaceAll(RegExp(r'\s+'), '');

    // Codifica el mensaje completamente
    final String encodedText = Uri.encodeFull(text);

    final Uri whatsappWebUri = Uri.parse("https://wa.me/$fullPhoneNumber?text=$encodedText");

    if (!await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se puede enviar un mensaje a $fullPhoneNumber');
    }
  }

  void showNoWhatsAppInstalledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('WhatsApp no instalado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          content: const Text('No tienes WhatsApp en tu dispositivo. Instálalo e intenta de nuevo'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar', style: TextStyle(color: negro, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  void makePhoneCall(String phoneNumber) async {
    final phoneCallUrl = 'tel:$phoneNumber';

    try {
      await launch(phoneCallUrl);
    } catch (e) {
      print('No se pudo realizar la llamada: $e');
    }
  }

  Widget verPaginaantecedentes() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: Uri.parse('https://antecedentes.policia.gov.co:7005/WebJudicial/'),
          ),
          onWebViewCreated: (InAppWebViewController controller) {
            inAppWebViewController = controller;
          },
          onProgressChanged: (InAppWebViewController controller, int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
        ),
        _progress < 1 ? Container(
          child: LinearProgressIndicator(
            backgroundColor: grisMedio,
            minHeight: 8,
            value: _progress,
          ),
        ) : const SizedBox()
      ],
    );
  }

  Widget verPaginaRuntVehiculo() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: Uri.parse('https://www.runt.com.co/consultaCiudadana/#/consultaVehiculo'),
          ),
          onWebViewCreated: (InAppWebViewController controller) {
            inAppWebViewController = controller;
          },
          onProgressChanged: (InAppWebViewController controller, int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
        ),
        _progress < 1 ? Container(
          child: LinearProgressIndicator(
            backgroundColor: grisMedio,
            minHeight: 8,
            value: _progress,
          ),
        ) : const SizedBox()
      ],
    );
  }

  Widget verPaginaRuntConductor() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: Uri.parse('https://portalpublico.runt.gov.co/#/consulta-ciudadano-documento/consulta/consulta-ciudadano-documento'),
          ),
          onWebViewCreated: (InAppWebViewController controller) {
            inAppWebViewController = controller;
          },
          onProgressChanged: (InAppWebViewController controller, int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
        ),
        _progress < 1 ? Container(
          child: LinearProgressIndicator(
            backgroundColor: grisMedio,
            minHeight: 8,
            value: _progress,
          ),
        ) : const SizedBox()
      ],
    );
  }



  //Funciones para calcular la fecha real de vencimiento

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


  Color _colorEstado(VigenciaEstado e) {
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

  Widget badgeVigencia({
    required String? fechaBd,
    required DateTime? Function(String?) calcularVence,
    int diasAlerta = 30,
  }) {
    final fechaVence = calcularVence(fechaBd);
    final info = calcularEstadoVigencia(fechaVence, diasAlerta: diasAlerta);
    final c = _colorEstado(info.estado);

    final venceStr = (info.fechaVence == null)
        ? ""
        : DateFormat('dd/MM/yyyy').format(info.fechaVence!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        border: Border.all(color: c, width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        venceStr.isEmpty ? textoEstado(info) : "${textoEstado(info)} · Vence: $venceStr",
        style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }

  Widget _dateWithBadge({
    required String label,
    required String key,
    required String initialValue,
    required String? fechaBd,
    required DateTime? Function(String?) calcularVence,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildDateField(
            label: label,
            key: key,
            initialValue: initialValue,
          ),
        ),
        const SizedBox(width: 10),
        badgeVigencia(
          fechaBd: fechaBd,
          calcularVence: calcularVence,
          diasAlerta: 30,
        ),
      ],
    );
  }

}
// class para calcular la fecha real de vencimiento
enum VigenciaEstado { sinFecha, vencido, porVencer, vigente }

class VigenciaInfo {
  final VigenciaEstado estado;
  final int? diasRestantes;
  final DateTime? fechaVence;

  VigenciaInfo(this.estado, this.diasRestantes, this.fechaVence);
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


