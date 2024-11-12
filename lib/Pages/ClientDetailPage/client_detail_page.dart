
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/main_layout.dart';
import '../../models/operador_model.dart';
import '../../models/usuario_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';

class ClientDetailPage extends StatefulWidget {

  final Client client;

  const ClientDetailPage({Key? key, required this.client}) : super(key: key);

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final ClientProvider _clientProviderr = ClientProvider();
  bool isDocumentodeidentidadVisible = false;
  bool isComunicacionNotificacionesVisible = false;
  String? selectedTipoDocumento;
  String? selectedGenero;
  String? rol;
  double averageRating = 0.0;

  Operador? operador;
  OperadorProvider _operadorProvider = OperadorProvider();
  MyAuthProvider _authProvider = MyAuthProvider();


  @override
  void initState() {
    super.initState();
    selectedTipoDocumento = widget.client.the03TipoDeDocumento;
    selectedGenero = widget.client.the09Genero;
    getClientRatings();

  }

  Color getStatusColor() {
    if (widget.client.verificacionStatus == "registrado"
    ) {
      return Colors.blueGrey;
    }
    else if (widget.client.verificacionStatus == "foto_tomada") {
      return Colors.amber;
    }
    else if (widget.client.verificacionStatus == 'Procesando') {
      return Colors.blueAccent;
    }
    else if (widget.client.verificacionStatus == 'corregida') {
      return Colors.purple;
    }

    else if (widget.client.verificacionStatus == 'activado') {
      return Colors.green;
    }
    else if (widget.client.verificacionStatus == 'bloqueado') {
      return Colors.red.shade900;
    }
    else if (widget.client.verificacionStatus == '') {
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
      pageTitle:  "Clientes",
      content: Column(
        children: [
          SizedBox(height: MediaQuery
              .of(context)
              .padding
              .top),
          Expanded(
            child: SingleChildScrollView(
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
                          _seccionComunicacionNotificaciones(),
                          const SizedBox(height: 50,)
                        ],
                      ),
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
  /////// widgets interfaz/////////////////////////////////////////

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
              widget.client.id,
              style: TextStyle(fontSize: fontSize),
            ),
            isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.client.the01Nombres} ${widget.client.the02Apellidos}', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold), ),
                Text('Cliente desde: ${widget.client.the21FechaDeRegistro}',
                  style: TextStyle(fontSize: fontSize),
                ),
                Divider(),

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
                    Text('${widget.client.the01Nombres} ${widget.client.the02Apellidos}', style: const TextStyle( fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Cliente desde: ${widget.client.the21FechaDeRegistro}',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ],
                ),
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
            _buildSectionTitle('Datos Generales' ),
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
                                    _buildDocumentPhoto("Cédula parte delantera", widget.client.fotoCedulaDelantera),
                                    Positioned(
                                      top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
                                      right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: getStatusColorFotos(widget.client.the13FotoCedulaDelantera),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                _buildTextField(widget.client.the01Nombres, 'Nombres', "01_Nombres"),
                                _buildTextField(widget.client.the02Apellidos, 'Apellidos', "02_Apellidos"),
                                _dropTipoDocumento (),
                                _buildTextField(widget.client.the04NumeroDocumento, 'Número de Documento', "04_Numero_documento"),
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
                                          _saveField("Verificacion_Status", "rechazada", () {});

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
                                        onPressed: () async {
                                          const url = 'https://antecedentes.policia.gov.co:7005/WebJudicial/';
                                          if (await canLaunch(url)) {
                                            await launch(url);
                                          } else {
                                            throw 'Could not launch $url';
                                          }

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
                                    _buildDocumentPhoto("Cédula parte trasera", widget.client.fotoCedulaTrasera),
                                    Positioned(
                                      top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
                                      right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: getStatusColorFotos(widget.client.the14FotoCedulaTrasera),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                _buildTextField(widget.client.the05FechaExpedicionDocumento, 'Fecha de expedición', "05_Fecha_expedicion_documento"),
                                _buildTextField(widget.client.the08FechaNacimiento, 'Fecha de nacimiento', "08_Fecha_nacimiento"),
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
                                          _saveField("Verificacion_Status", "rechazada", () {});

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
                                      _buildDocumentPhoto("Cédula parte delantera", widget.client.fotoCedulaDelantera),
                                      Positioned(
                                        top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
                                        right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: getStatusColorFotos(widget.client.the13FotoCedulaDelantera),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildTextField(widget.client.the01Nombres, 'Nombres', "01_Nombres"),
                                  _buildTextField(widget.client.the02Apellidos, 'Apellidos', "02_Apellidos"),
                                  _dropTipoDocumento (),
                                  _buildTextField(widget.client.the04NumeroDocumento, 'Número de Documento', "04_Numero_documento"),
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
                                            _saveField("Verificacion_Status", "rechazada", () {});
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
                                      _buildDocumentPhoto("Cédula parte trasera", widget.client.fotoCedulaTrasera),
                                      Positioned(
                                        top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
                                        right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: getStatusColorFotos(widget.client.the14FotoCedulaTrasera),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  _buildTextField(widget.client.the05FechaExpedicionDocumento, 'Fecha de expedición', "05_Fecha_expedicion_documento"),
                                  _buildTextField(widget.client.the08FechaNacimiento, 'Fecha de nacimiento', "08_Fecha_nacimiento"),
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
                                            _saveField("Verificacion_Status", "rechazada", () {});

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
                                  textStyle: TextStyle(fontSize: 16),
                                ),
                                icon: Icon(Icons.add_chart_sharp, color: Colors.white), // Icono de Correo
                                label: Text('Antecedentes', style: TextStyle( color: blanco)),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 20),
                              height: 50, // Altura del botón
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Lógica para informar activación por Mail
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 20), backgroundColor: Colors.redAccent, // Color de fondo del botón
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: TextStyle(fontSize: 16),
                                ),
                                icon: Icon(Icons.cancel, color: Colors.white), // Icono de Correo
                                label: Text('Bloqueo AJ', style: TextStyle( color: blanco)),
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



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
        _buildPerfilPhoto(widget.client.image),
        Positioned(
          top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
          right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: getStatusColorFotos(widget.client.the15FotoPerfilUsuario),
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
        _buildInfoRowHorizontal('Fecha activación:   ', widget.client.the11FechaActivacion),
        _buildInfoRowHorizontal('Activador:   ', widget.client.the12NombreActivador),
        _buildInfoRowHorizontal('Email:   ', widget.client.the06Email),
        _buildInfoRowHorizontal('Celular:   ', widget.client.the07Celular),
        _buildInfoRowHorizontal('Viajes:   ', widget.client.the19Viajes.toString()),
        _buildInfoRowHorizontalIconoEstrella('Calificación:   ', averageRating.toStringAsFixed(1)),
        _buildInfoRowHorizontalIconocancel('Cancelaciones:   ', widget.client.the22Cancelaciones.toString()),
      ],
    );
  }

  void getClientRatings() async {
    final clientId = widget.client.id;
    print("*Este es el id del cliente**********************$clientId");// Obtienes el ID del conductor

    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('Clients')
          .doc(clientId)
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
              padding: EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.red, // Color de fondo del botón
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: TextStyle(fontSize: 16),
            ),
            icon: Icon(Icons.block, color: Colors.white), // Icono de Correo
            label: Text('BLOQUEAR', style: TextStyle(color: Colors.white, fontSize: 12)),
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
              padding: EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.green, // Color de fondo del botón
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: TextStyle(fontSize: 16),
            ),
            icon: Icon(Icons.check_circle, color: Colors.white), // Icono de Correo
            label: Text('ACTIVAR', style: TextStyle(color: Colors.white, fontSize: 12)),
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
              padding: EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.green, // Color de fondo del botón
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: TextStyle(fontSize: 16),
            ),
            icon: Icon(Icons.check_circle, color: Colors.white), // Icono de Correo
            label: Text('ACTIVAR', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                  DropdownMenuItem(value: "Cédula de Ciudadanía", child: Text("Cédula de Ciudadanía")),
                  DropdownMenuItem(value: "Cédula de extranjería", child: Text("Cédula de extranjería")),
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
              icon: Icon(Icons.save),
              onPressed: () {
                _saveField("03_Tipo_de_documento", selectedTipoDocumento!, () {
                  setState(() {
                    widget.client.the03TipoDeDocumento;
                  });
                });
              },
            ),
          ],
        ),
        SizedBox(height: 10)
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                _saveField("09_Genero", selectedGenero!, () {
                  widget.client.the09Genero;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 10)
      ],
    );
  }

  //// widget para textedit strings////////
  Widget _buildTextField(String initialValue, String label, String key) {
    TextEditingController controller = TextEditingController(text: initialValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              _saveField(key, controller.text, () {

              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void activarUsuario(BuildContext context) {
    String message;
    bool canActivate = false; // Variable para determinar si se puede activar el usuario

    // Verificar si el conductor ya está activado
    if (widget.client.the10EstaActivado == true) {
      message = 'El cliente ya se encuentra activado';
    } else {
      // Condiciones para determinar si se puede activar el usuario
      if (widget.client.the15FotoPerfilUsuario == "aceptada" &&
          widget.client.the13FotoCedulaDelantera == "aceptada" &&
          widget.client.the14FotoCedulaTrasera == "aceptada" &&
          widget.client.the05FechaExpedicionDocumento.isNotEmpty &&
          widget.client.the08FechaNacimiento.isNotEmpty &&
          widget.client.the09Genero.isNotEmpty) {
        message = 'El cliente ya puede ser activado';
        canActivate = true;
      } else {
        message = 'Hay alguna verificación que no se ha hecho y evita activar al cliente';
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Activar Cliente'),
          content: Text(message),
          actions: <Widget>[
            if (canActivate)
              TextButton(
                child: const Text('Activar'),
                onPressed: () {
                  _saveFieldBool("10_Esta_activado", true);
                  _saveFieldBool("16_Esta_bloqueado", false);
                  _saveField("Verificacion_Status", "activado", () {}); // Llama al método para guardar el campo

                  setState(() {
                    widget.client.the10EstaActivado = true;
                    widget.client.the16EstaBloqueado = false;
                    widget.client.verificacionStatus = "activado";
                  });

                  Navigator.of(context).pop(); // Cerrar el diálogo
                },
              ),
          ],
        );
      },
    );
  }

  void bloquearUsuario(BuildContext context) {

    // Verificar si el usuario ya está bloqueado
    if (widget.client.the16EstaBloqueado == true) {
      // Si ya está bloqueado, mostramos el mensaje y salimos
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bloquear Cliente'),
            content: const Text('El cliente ya se encuentra bloqueado'),
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

    // Si el usuario no está bloqueado, procedemos a bloquearlo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bloquear Cliente'),
          content: const Text('¿Está seguro de bloquear al cliente?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Bloquear'),
              onPressed: () {
                _saveFieldBool("16_Esta_bloqueado", true); // Marcar como bloqueado
                _saveFieldBool("10_Esta_activado", false); // Marcar como bloqueado
                _saveField("Verificacion_Status", "bloqueado", () {}); // Actualizar el estado

                setState(() {
                  widget.client.the10EstaActivado = false;
                  widget.client.the16EstaBloqueado = true;
                  widget.client.verificacionStatus = "bloqueado";
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

  void _showConfirmationDialogActivarusuario(BuildContext context, String message, bool isBloquear) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("No"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: Text("Sí"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                activarUsuario(context); // Llama al método para activar el usuario

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
              child: Text("No"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: Text("Sí"),
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
              child: Text("Sí"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _saveField("15_Foto_perfil_usuario", isBloquear, () {});

                setState(() {
                  widget.client.the15FotoPerfilUsuario = isBloquear;
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
              child: Text("Sí"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _saveField("13_Foto_cedula_delantera", isBloquear, () {}); // Llama al método para guardar el campo
                setState(() {
                  widget.client.the13FotoCedulaDelantera = isBloquear;
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
              child: Text("Sí"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _saveField("14_Foto_cedula_trasera", isBloquear, () {}); // Llama al método para guardar el campo
                setState(() {
                  widget.client.the14FotoCedulaTrasera = isBloquear;
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
          .collection('Clients')
          .doc(widget.client.id)
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
      await _clientProviderr.update(data, widget.client.id);
      _showSnackBar(context, 'Actualización exitosa');
    } catch (error) {
      _showSnackBar(context, 'Error al actualizar el cliente: $error');
    }
  }


  //// metodo para guardar los editfield strings/////
  void _saveField(String key, dynamic value, Function updateStateCallback) async {
    print("Guardando campo con key '$key' y valor '$value'");

    Map<String, dynamic> data = {
      key: value,
    };

    try {
      await _clientProviderr.update(data, widget.client.id);
      _showSnackBar(context, 'Actualización exitosa');

      // Llamar al callback de actualización del estado
      updateStateCallback();
    } catch (error) {
      _showSnackBar(context, 'Error al actualizar el cliente: $error');
    }
  }


  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  Widget _buildVerificationStatus(double fontSize) {
    Color statusColor = getStatusColor();
    String statusText = '';

    if (widget.client.verificacionStatus == "registrado") {
      statusText = 'Registrado';
    } else if (widget.client.verificacionStatus == "foto_tomada") {
      statusText = 'Fotos faltantes';
    } else if (widget.client.verificacionStatus == 'Procesando') {
      statusText = 'Procesando';
    }
    else if (widget.client.verificacionStatus == 'corregida') {
      statusText = 'Corregida';
    }
    else if (widget.client.verificacionStatus == 'rechazada') {
      statusText = 'En espera';
    }
    else if (widget.client.verificacionStatus == 'activado') {
      statusText = 'Activado';
    }
    else if (widget.client.verificacionStatus == 'bloqueado') {
      statusText = 'Bloqueado';
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
        style: TextStyle(fontWeight: FontWeight.bold),
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
            style: TextStyle(fontWeight: FontWeight.bold),
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
        Text(value, style: const TextStyle(fontSize: 12)),
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

}
