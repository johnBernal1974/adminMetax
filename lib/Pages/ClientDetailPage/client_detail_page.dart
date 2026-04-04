
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String? selectedRol;
  String? rol;
  String? nameOperador;
  String? apellidosOperador;
  double averageRating = 0.0;

  Operador? operador;
  OperadorProvider _operadorProvider = OperadorProvider();
  MyAuthProvider _authProvider = MyAuthProvider();

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};



  @override
  void initState() {
    super.initState();
    getOperadorInfo();
    selectedGenero = widget.client.genero;
    selectedRol = widget.client.rol;
    selectedTipoDocumento = widget.client.tipoDocumento;


    _initController("01_Nombres", widget.client.nombres);
    _initController("02_Apellidos", widget.client.apellidos);
    _initController("03_Numero_Documento", widget.client.numeroDocumento);


    getClientRatings();


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


  void _initController(String key, String? value) {
    _controllers[key] = TextEditingController(text: value ?? '');
    _focusNodes[key] = FocusNode();
  }

  Color getStatusColor() {
    switch (widget.client.status) {
      case "registrado":
        return Colors.grey;

      case "procesando":
        return Colors.blue;

      case "activado":
        return Colors.green;

      case "bloqueado":
        return Colors.red.shade900;

      default:
        return Colors.grey;
    }
  }

  Color getStatusColorFotos(String estado) {
    switch (estado) {
      case "rechazada":
        return Colors.red;

      case "corregida":
        return Colors.purple;

      case "aprobada":
        return Colors.green;

      case "tomada":
        return Colors.blue;

      default:
        return Colors.grey;
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
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Clients')
                      .doc(widget.client.id)
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;

                    final client = Client.fromJson(data); // 👈 CLAVE

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _encabezadoSeccion(client),
                              const Divider(),
                              _seccionDatosGenerales(client),
                              const Divider(),
                              _seccionDocumentosdeIdentidad(client),
                              const Divider(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  /////// widgets interfaz/////////////////////////////////////////

  Widget _encabezadoSeccion(Client client) {
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
              client.id,
              style: TextStyle(fontSize: fontSize),
            ),
            isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${client.nombres} ${client.apellidos}', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold), ),
                Text('Cliente desde: ${client.fechaRegistro}'),
                const Divider(),
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
                    Text('${client.nombres} ${client.apellidos}', style: const TextStyle( fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Cliente desde: ${client.fechaRegistro}')

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

  Widget _seccionDatosGenerales(Client client) {
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
                _buildSectionTitle('Datos Generales' ),
                botonesComunicacion(context)
              ],
            ),
            isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoColumns(client),
                const SizedBox(height: 25),
                _buildActionButtonRow(context, client),
                const SizedBox(height: 25),
                Row(
                  children: [
                    _buildPhotoStack(client),
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
                    _buildPhotoStack(client),
                    const SizedBox(height: 30),
                    _buildButtonRowAceptarRechazarFotoPerfil(context),
                  ],
                ),
                const SizedBox(width: 50),
                _buildInfoColumns(client),
                const SizedBox(width: 150),
                _buildActionButtonColumn(context, client),
              ],
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
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
            makePhoneCall(widget.client.celular);
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

  void _openWhatsApp(BuildContext context) async {
    String phoneNumber = widget.client.celular;
    String? name = widget.client.nombres;
    String message = 'Hola $name, mi nombre es $nameOperador del equipo de asistencia de Metax.';
    final whatsappLink = Uri.parse('whatsapp://send?phone=+57$phoneNumber&text=$message');
    try {
      await launchUrl(whatsappLink);
    } catch (e) {
      showNoWhatsAppInstalledDialog(context);
    }
  }


  void _openWhatsAppActivacion(BuildContext context) async {
    String phoneNumber = widget.client.celular;
    String? clientName = widget.client.nombres;
    String message = '''Hola *$clientName*,

Soy $nameOperador del grupo de soporte de *Metax* y me complace informarte que tu cuenta de *Cliente* ya está activada.

¡Ingresa ahora mismo a tu aplicación y empieza a recorrer la ciudad!

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
    String phoneNumber = widget.client.celular;
    String? name = widget.client.nombres;
    String message = 'Hola $name, mi nombre es $nameOperador del equipo de asistencia de Metax.';
    sendWhatsAppWeb(phone: phoneNumber, text: message);
  }

  void _openWhatsAppWebActivacion(BuildContext context) async {
    String phoneNumber = widget.client.celular;
    String? clientName = widget.client.nombres;

    String message = '''Hola *$clientName*,

Soy $nameOperador del grupo de soporte de *Metax* y me complace informarte que tu cuenta de *Cliente* ya está activada.

¡Ingresa ahora mismo a tu aplicación y empieza a recorrer la ciudad!

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

  void makePhoneCall(String phoneNumber) async {
    final phoneCallUrl = 'tel:$phoneNumber';

    try {
      await launch(phoneCallUrl);
    } catch (e) {
      print('No se pudo realizar la llamada: $e');
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


  void getOperadorInfo() async {
    var user = _authProvider.getUser();
    if (user != null) {
      operador = await _operadorProvider.getById(user.uid);
      if (operador != null) {
        nameOperador =operador?.the01Nombres;
        apellidosOperador =operador?.the02Apellidos;
      }
    }
    print('Datos del operador ***************************************** $rol');
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
              _showConfirmationFotoPerfil(context, "¿Aceptar la foto de perfil?", "aprobada");
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

  Widget _buildPhotoStack(Client client) {
    return Stack(
      clipBehavior: Clip.none,  // Permitir que los elementos dentro del Stack se dibujen fuera de sus límites
      children: [
        _buildPerfilPhoto(client.fotoPerfilUrl),
        Positioned(
          top: -10,  // Ajusta la posición vertical para que el círculo no quede recortado
          right: -10,  // Ajusta la posición horizontal para que el círculo no quede recortado
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: getStatusColorFotos(client.fotoPerfilEstado),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumns(Client client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRowHorizontal('Celular:   ', client.celular),
        _buildInfoRowHorizontal('Viajes:   ', client.viajes.toString()),
        _buildInfoRowHorizontalIconoEstrella('Calificación:   ', averageRating.toStringAsFixed(1)),
        _buildInfoRowHorizontalIconocancel('Cancelaciones:   ', client.cancelaciones.toString()),
        _buildInfoRowHorizontalTpoBold('Rol:   ', client.rol.toString()),
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

  Widget _buildActionButtonColumn(BuildContext context, Client client) {
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
              textStyle: TextStyle(fontSize: 16),
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
              _showConfirmationDialogActivarusuario(
                context,
                "¿Está seguro de activar este cliente?",
                false,
                client,
              );
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

  Widget _buildActionButtonRow(BuildContext context, Client client) {
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
              _showConfirmationDialogActivarusuario(
                context,
                "¿Está seguro de activar este cliente?",
                false,
                client,
              );
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
                  setState(() => selectedGenero = value);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final valueToSave = (selectedGenero ?? "").trim();

                _saveField("09_Genero", valueToSave, () {
                  setState(() {
                    widget.client.genero = valueToSave;
                  });
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  Widget _dropRol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rol', style: TextStyle(fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedRol,
                items: const [
                  DropdownMenuItem(value: "", child: Text("")),
                  DropdownMenuItem(value: "regular", child: Text("regular")),
                  DropdownMenuItem(value: "hotel", child: Text("hotel")),
                  DropdownMenuItem(value: "turismo", child: Text("turismo")),
                ],
                onChanged: (value) {
                  setState(() => selectedRol = value);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final valueToSave = (selectedRol ?? "").trim();

                _saveField("20_Rol", valueToSave, () {
                  setState(() {
                    widget.client.rol = valueToSave;
                  });
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
            onPressed: () {
              final valueToSave = controller.text;

              _saveField(key, valueToSave, () {
                setState(() {
                  if (key == "01_Nombres") widget.client.nombres = valueToSave;
                  if (key == "02_Apellidos") widget.client.apellidos = valueToSave;
                  if (key == "03_Numero_Documento") widget.client.numeroDocumento = valueToSave;
                });
              });

              focusNode.unfocus();
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }


  void activarUsuario(BuildContext context, Client client) {

    final faltantes = validarCamposFaltantes(client);
    bool canActivate = faltantes.isEmpty;

    String message;

    if (client.status == "activado") {
      message = 'El cliente ya se encuentra activado';
    }
    else if (!canActivate) {
      message = 'No se puede activar.\n\nFaltan:\n- ${faltantes.join("\n- ")}';
    }
    else {
      message = 'El cliente cumple todos los requisitos y puede ser activado';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Activar Cliente'),
        content: Text(message),
        actions: [

          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.pop(context),
          ),

          if (canActivate && client.status != "activado")
            TextButton(
              child: const Text('Activar'),
              onPressed: () async {

                await FirebaseFirestore.instance
                    .collection('Clients')
                    .doc(client.id)
                    .update({
                  "status": "activado"
                });

                Navigator.pop(context);

                if (!kIsWeb) {
                  _openWhatsAppActivacion(context);
                } else {
                  _openWhatsAppWebActivacion(context);
                }
              },
            ),
        ],
      ),
    );
  }

  bool puedeActivarse(Client client) {

    // ✅ 1. FOTO PERFIL OBLIGATORIA
    final fotoOk = client.fotoPerfilEstado == "aprobada";

    // ✅ 2. VIAJES (mínimo 1 por ejemplo, puedes cambiar)
    final viajesOk = client.viajes >= 1;

    // ✅ 3. DATOS OBLIGATORIOS
    final datosOk =
        client.nombres.isNotEmpty &&
            client.apellidos.isNotEmpty &&
            client.celular.isNotEmpty &&
            client.genero.isNotEmpty &&
            client.rol.isNotEmpty;

    return fotoOk && viajesOk && datosOk;
  }

  List<String> validarCamposFaltantes(Client client) {
    List<String> faltantes = [];

    if (client.fotoPerfilEstado != "aprobada") {
      faltantes.add("Foto de perfil no aprobada");
    }

    if (client.nombres.isEmpty) faltantes.add("Nombres");
    if (client.apellidos.isEmpty) faltantes.add("Apellidos");
    if (client.celular.isEmpty) faltantes.add("Celular");
    if (client.genero.isEmpty) faltantes.add("Género");
    if (client.rol.isEmpty) faltantes.add("Rol");

    return faltantes;
  }

  void bloquearUsuario(BuildContext context) {

    // Verificar si el usuario ya está bloqueado
    if (widget.client.status == "bloqueado") {
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
                _saveField("status", "bloqueado", () {}); // Actualizar el estado

                setState(() {
                  widget.client.status = "bloqueado";
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

  void _showConfirmationDialogActivarusuario(
      BuildContext context,
      String message,
      bool isBloquear,
      Client client,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Sí"),
            onPressed: () {
              Navigator.pop(context);
              activarUsuario(context, client);
            },
          ),
        ],
      ),
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
                _saveField("foto_perfil_estado", isBloquear, () {});

                setState(() {
                  widget.client.fotoPerfilEstado = isBloquear;
                });// Llama al método para guardar el campo
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildButtonRowAceptarRechazarNombre(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ✅ ACEPTAR
        SizedBox(
          height: 30,
          width: 30,
          child: ElevatedButton(
            onPressed: () {
              _showConfirmationNombre(
                context,
                "¿Aceptar nombre del cliente?",
                "aprobada",
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ),
        ),

        const SizedBox(width: 35),

        // ❌ RECHAZAR
        SizedBox(
          height: 30,
          width: 30,
          child: ElevatedButton(
            onPressed: () {
              _showConfirmationNombre(
                context,
                "¿Rechazar nombre del cliente?",
                "rechazado",
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.block, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  void _showConfirmationNombre(BuildContext context, String message, String value) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              _saveField("nombre_estado", value, () {});

              setState(() {
                // opcional si quieres reflejarlo localmente
              });
            },
            child: const Text("Sí"),
          ),
        ],
      ),
    );
  }

  //// metodo para guardar los editfield strings/////
  void _saveField(String key, dynamic value, Function updateStateCallback) async {
    print("Guardando campo con key '$key' y valor '$value'");

    Map<String, dynamic> data = {
      key: value,
    };

    try {
      await _clientProviderr.update(data, widget.client.id);
      if (!mounted) return;
      _showSnackBar(context, 'Actualización exitosa');
      updateStateCallback();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(context, 'Error al actualizar el cliente: $error');
    }

  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildVerificationStatus(double fontSize) {
    Color statusColor = getStatusColor();
    String statusText = '';

    switch (widget.client.status) {
      case "registrado":
        statusText = 'Registrado';
        break;

      case "procesando":
        statusText = 'En validación';
        break;

      case "activado":
        statusText = 'Activado';
        break;

      case "bloqueado":
        statusText = 'Bloqueado';
        break;

      default:
        statusText = 'Sin estado';
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

  Widget _buildInfoRowHorizontalTpoBold(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (photoUrl != null && photoUrl.isNotEmpty)
                  ? Image.network(
                photoUrl,
                key: ValueKey(photoUrl), // 🔥 SOLUCIÓN
                fit: BoxFit.cover,
                errorBuilder: (context, exception, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, color: Colors.grey, size: 50),
                        SizedBox(height: 10),
                        Text('Foto no disponible',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              )
                  : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, color: Colors.grey, size: 50),
                    SizedBox(height: 10),
                    Text('Foto no disponible',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _seccionDocumentosdeIdentidad(Client client) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        bool isMobile = screenWidth < 600;

        return Column(
          children: [
            isMobile
                ? Column(
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
                      child: _buildSectionTitle('Documento de identidad'),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isDocumentodeidentidadVisible = !isDocumentodeidentidadVisible;
                        });
                      },
                      icon: Icon(
                        isDocumentodeidentidadVisible
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
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
                                clipBehavior: Clip.none,
                                children: [
                                  _buildDocumentPhoto(
                                    "Cédula parte delantera",
                                    client.cedulaFrontalUrl,
                                  ),
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: getStatusColorFotos(
                                          client.cedulaFrontalEstado,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // ✅ Si quieres mostrar nombres/apellidos como en conductor (ya los tienes)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // 🔥 CAMPOS
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildTextField(client.nombres, 'Nombres', "01_Nombres"),
                                        _buildTextField(client.apellidos, 'Apellidos', "02_Apellidos"),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // 🔥 INDICADOR DE ESTADO (AQUÍ USAS TU FUNCIÓN)
                                  Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: getNombreStatusColor(client.nombreEstado),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildButtonRowAceptarRechazarNombre(context),
                              _dropTipoDocumentoClient(),
                              _buildTextField(client.numeroDocumento, 'Número de Documento', "03_Numero_Documento"),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showConfirmationCedulaFrontal(
                                          context,
                                          "¿Aceptar la foto del documento de identidad en su parte delantera?",
                                          "aprobada",
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Icon(Icons.check_circle,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 25),
                                  SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showConfirmationCedulaFrontal(
                                          context,
                                          "¿Está seguro de rechazar la foto del documento en su parte delantera?",
                                          "rechazada",
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Icon(Icons.block,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),

                          Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _buildDocumentPhoto(
                                    "Cédula parte trasera",
                                    client.cedulaReversoUrl,
                                  ),
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: getStatusColorFotos(
                                          client.cedulaReversoEstado,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              _buildDateField(
                                label: 'Fecha de expedición',
                                key: '05_Fecha_Expedicion_Documento',
                                initialValue: client.fechaExpedicionDocumento ?? '',
                              ),

                              _buildDateField(
                                label: 'Fecha de nacimiento',
                                key: '08_Fecha_Nacimiento',
                                initialValue: client.fechaNacimiento ?? '',
                              ),


                              // ✅ si quieres que admin pueda cambiar género aquí también (ya tienes drop)
                              _dropGenero(),
                              _dropRol(),

                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showConfirmationCedulaReverso(
                                          context,
                                          "¿Aceptar la foto del documento de identidad en su parte trasera?",
                                          "aprobada",
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Icon(Icons.check_circle,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 25),
                                  SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showConfirmationCedulaReverso(
                                          context,
                                          "¿Está seguro de rechazar la foto del documento en su parte trasera?",
                                          "rechazada",
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Icon(Icons.block,
                                          color: Colors.white, size: 20),
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
            )
                : Column(
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
                      child: _buildSectionTitle('Documento de identidad'),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isDocumentodeidentidadVisible = !isDocumentodeidentidadVisible;
                        });
                      },
                      icon: Icon(
                        isDocumentodeidentidadVisible
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
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
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildDocumentPhoto(
                                      "Cédula parte delantera",
                                      client.cedulaFrontalUrl,
                                    ),
                                    Positioned(
                                      top: -10,
                                      right: -10,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: getStatusColorFotos(
                                            client.cedulaFrontalEstado,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // 🔥 CAMPOS
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildTextField(client.nombres, 'Nombres', "01_Nombres"),
                                          _buildTextField(client.apellidos, 'Apellidos', "02_Apellidos"),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    // 🔥 INDICADOR DE ESTADO (AQUÍ USAS TU FUNCIÓN)
                                    Container(
                                      margin: const EdgeInsets.only(top: 10),
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: getNombreStatusColor(client.nombreEstado),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildButtonRowAceptarRechazarNombre(context),
                                _dropTipoDocumentoClient(),
                                _buildTextField(client.numeroDocumento, 'Número de Documento', "03_Numero_Documento"),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationCedulaFrontal(
                                            context,
                                            "¿Aceptar la foto del documento de identidad en su parte delantera?",
                                            "aprobada",
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Icon(Icons.check_circle,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationCedulaFrontal(
                                            context,
                                            "¿Está seguro de rechazar la foto del documento en su parte delantera?",
                                            "rechazada",
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Icon(Icons.block,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildDocumentPhoto(
                                      "Cédula parte trasera",
                                      client.cedulaReversoUrl,
                                    ),
                                    Positioned(
                                      top: -10,
                                      right: -10,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: getStatusColorFotos(
                                            client.cedulaReversoEstado,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                _buildDateField(
                                  label: 'Fecha de expedición',
                                  key: '05_Fecha_Expedicion_Documento',
                                  initialValue: client.fechaExpedicionDocumento ?? '',
                                ),

                                _buildDateField(
                                  label: 'Fecha de nacimiento',
                                  key: '08_Fecha_Nacimiento',
                                  initialValue: client.fechaNacimiento ?? '',
                                ),

                                _dropGenero(),
                                _dropRol(),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationCedulaReverso(
                                            context,
                                            "¿Aceptar la foto del documento de identidad en su parte trasera?",
                                            "aprobada",
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Icon(Icons.check_circle,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationCedulaReverso(
                                            context,
                                            "¿Está seguro de rechazar la foto del documento en su parte trasera?",
                                            "rechazada",
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Icon(Icons.block,
                                            color: Colors.white, size: 20),
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
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Color getNombreStatusColor(String estado) {
    switch (estado) {
      case "rechazado":
        return Colors.red;
      case "corregida":
        return Colors.purple;
      case "aprobada":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showConfirmationCedulaFrontal(BuildContext context, String message, String value) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _saveField("cedula_frontal_estado", value, () {});
              setState(() {
                widget.client.cedulaFrontalEstado = value;
              });
            },
            child: const Text("Sí"),
          ),
        ],
      ),
    );
  }

  void _showConfirmationCedulaReverso(BuildContext context, String message, String value) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
             _saveField("cedula_reverso_estado", value, () {});
              setState(() {
                widget.client.cedulaReversoEstado = value;
              });
            },
            child: const Text("Sí"),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String key,
    required String initialValue,
  }) {
    final controller = _controllers[key] ??= TextEditingController(text: initialValue);
    final focusNode = _focusNodes[key] ??= FocusNode();

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

      controller.text = formatted;

      // ✅ 2) guarda en Firestore
      _saveField(key, formatted, () {});


      if (mounted) setState(() {});
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: true,
        onTap: _pickDate,
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



  Widget _buildDocumentPhoto(String title, String? photoUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (photoUrl != null && photoUrl.isNotEmpty)
                  ? GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(photoUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Foto no disponible', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              )
                  : const Center(
                child: Text('Foto no disponible', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropTipoDocumentoClient() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de documento', style: TextStyle(fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedTipoDocumento,
                items: const [
                  DropdownMenuItem(value: "", child: Text("")),
                  DropdownMenuItem(value: "CC", child: Text("Cédula de ciudadanía")),
                  DropdownMenuItem(value: "CE", child: Text("Cédula de extranjería")),
                ],
                onChanged: (value) {
                  setState(() => selectedTipoDocumento = value);
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

                _saveField("04_Tipo_Documento", valueToSave, () {
                  setState(() {
                    widget.client.tipoDocumento = valueToSave;
                  });
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  //HELPERS

  void _showConfirmationCedula(
      BuildContext context,
      String message,
      String fieldKey,
      String value,
      VoidCallback onLocalUpdate,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _saveField(fieldKey, value, () {});
              onLocalUpdate();
            },
            child: const Text("Sí"),
          ),
        ],
      ),
    );
  }

}
