
import 'package:flutter/material.dart';
import 'package:tay_rona_administrador/models/operador_model.dart';
import 'package:tay_rona_administrador/providers/operador_provider.dart';
import '../../common/main_layout.dart';
import '../../providers/auth_provider.dart';
import '../../src/color.dart';

class OperadorDetailPage extends StatefulWidget {

  final Operador operador;

  const OperadorDetailPage({Key? key, required this.operador}) : super(key: key);

  @override
  State<OperadorDetailPage> createState() => _OperadorDetailPageState();
}

class _OperadorDetailPageState extends State<OperadorDetailPage> {
  final OperadorProvider _operadorProvider = OperadorProvider();
  bool isDocumentodeidentidadVisible = false;
  String? selectedTipoDocumento;
  String? selectedRol;
  String? rol;
  Operador? operador;
  MyAuthProvider _authProvider = MyAuthProvider();

  @override
  void initState() {
    super.initState();
    selectedTipoDocumento = widget.operador.the05TipoDocumento;
    selectedRol = widget.operador.the20Rol;

  }

  Color getStatusColor() {
    if (widget.operador.verificacionStatus == "registrado"
    ) {
      return Colors.blueGrey;
    }

    else if (widget.operador.verificacionStatus == 'activado') {
      return Colors.green;
    }
    else if (widget.operador.verificacionStatus == 'bloqueado') {
      return Colors.red.shade900;
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
      pageTitle:  "Operadores",
      content: Column(
        children: [
          SizedBox(height: MediaQuery
              .of(context)
              .padding
              .top), // 
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
                    Text("este es el operador"),
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
              widget.operador.id,
              style: TextStyle(fontSize: fontSize),
            ),
            isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.operador.the01Nombres} ${widget.operador.the02Apellidos}', style: const TextStyle( fontSize: 18, fontWeight: FontWeight.bold), ),
                Text('Operador desde: ${widget.operador.the11FechaActivacion}',
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
                    Text('${widget.operador.the01Nombres} ${widget.operador.the02Apellidos}', style: const TextStyle( fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Operador desde: ${widget.operador.the11FechaActivacion}',
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
                _buildPhotoStack(),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoStack(),
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
                                _buildTextField(widget.operador.the01Nombres, 'Nombres', "01_Nombres"),
                                _buildTextField(widget.operador.the02Apellidos, 'Apellidos', "02_Apellidos"),
                                const SizedBox(height: 25),
                              ],
                            ),
                            Divider(),// Espacio entre columnas
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                _dropTipoDocumento (),
                                _buildTextField(widget.operador.the04NumeroDocumento, 'Número de Documento', "04_Numero_documento"),
                                _dropRol(),
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
                                  _buildTextField(widget.operador.the01Nombres, 'Nombres', "01_Nombres"),
                                  _buildTextField(widget.operador.the02Apellidos, 'Apellidos', "02_Apellidos"),
                                  _dropRol()

                                ],
                              ),
                            ),
                            const SizedBox(width: 20), // Espacio entre columnas
                            Expanded(
                              child: Column(
                                children: [
                                  _dropTipoDocumento (),
                                  _buildTextField(widget.operador.the04NumeroDocumento, 'Número de Documento', "04_Numero_documento"),
                                  const SizedBox(height: 30),
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
        }
    );
  }


  Widget _buildPhotoStack() {
    return Stack(
      clipBehavior: Clip.none,  // Permitir que los elementos dentro del Stack se dibujen fuera de sus límites
      children: [
        _buildPerfilPhoto(widget.operador.image),
      ],
    );
  }

  Widget _buildInfoColumns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRowHorizontal('Fecha Activación:   ', widget.operador.the11FechaActivacion),
        _buildInfoRowHorizontal('Nombre activador:   ', widget.operador.the12NombreActivador),
        _buildInfoRowHorizontal('Documento:   ', widget.operador.the04NumeroDocumento),
        _buildInfoRowHorizontal('Tipo Documento:   ', widget.operador.the05TipoDocumento),
        _buildInfoRowHorizontal('Email:   ', widget.operador.the06Email),
        _buildInfoRowHorizontal('Celular:   ', widget.operador.the07Celular),
        _buildInfoRowHorizontal('Rol:   ', widget.operador.the20Rol),
      ],
    );
  }

  Widget _buildActionButtonColumn(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40, // Altura del botón
          child: ElevatedButton.icon(
            onPressed: () {
              _showConfirmationDialogBloquearusuario(context, "¿Está seguro de bloquear este Operador?", true);
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
              icon: const Icon(Icons.save),
              onPressed: () {
                _saveField("05_Tipo_documento", selectedTipoDocumento!);
              },
            ),
          ],
        ),
        const SizedBox(height: 10)
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
                  DropdownMenuItem(value: "Master", child: Text("Master")),
                  DropdownMenuItem(value: "Master2", child: Text("Master2")),
                  DropdownMenuItem(value: "Coordinador Clientes", child: Text("Coordinador Clientes")),
                  DropdownMenuItem(value: "Coordinador Carros", child: Text("Coordinador Carros")),
                  DropdownMenuItem(value: "Coordinador Motos", child: Text("Coordinador Motos")),
                  DropdownMenuItem(value: "Coordinador Full", child: Text("Coordinador Full")),
                  DropdownMenuItem(value: "Clientes", child: Text("Clientes")),
                  DropdownMenuItem(value: "Carros", child: Text("Carros")),
                  DropdownMenuItem(value: "Motos", child: Text("Motos")),
                  DropdownMenuItem(value: "Conductores Full", child: Text("Conductores Full")),
                  DropdownMenuItem(value: "Recarga Carro", child: Text("Recarga Carro")),
                  DropdownMenuItem(value: "Recarga Moto", child: Text("Recarga Moto")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRol = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                _saveField("20_Rol", selectedRol!);
              },
            ),
          ],
        ),
        const SizedBox(height: 10)
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
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveField(key, controller.text);
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
    if (widget.operador.verificacionStatus == "activado") {
      message = 'El operador ya se encuentra activado';
    } else {
      // Condiciones para determinar si se puede activar el usuario
      if (widget.operador.image.isNotEmpty) {
        message = 'El operador ya puede ser activado';
        canActivate = true;
      } else {
        message = 'Hay alguna verificación que no se ha hecho y evita activar al operador';
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Activar Operador'),
          content: Text(message),
          actions: <Widget>[
            if (canActivate)
              TextButton(
                child: const Text('Activar'),
                onPressed: () {
                  _saveField("Verificacion_Status", "activado"); // Llama al método para guardar el campo

                  setState(() {

                    widget.operador.verificacionStatus = "activado";
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
    if (widget.operador.verificacionStatus == "bloqueado") {
      // Si ya está bloqueado, mostramos el mensaje y salimos
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bloquear Operador'),
            content: const Text('El Operador ya se encuentra bloqueado'),
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
          title: const Text('Bloquear Operador'),
          content: const Text('¿Está seguro de bloquear al operador?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Bloquear'),
              onPressed: () {
                _saveField("Verificacion_Status", "bloqueado" ); // Marcar como bloqueado
                setState(() {
                  widget.operador.verificacionStatus = "bloqueado";
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
              child: const Text("No"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: const Text("Sí"),
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

  //// metodo para guardar los editfield strings/////
  void _saveField(String key, dynamic value) async {
    print("Guardando campo con key '$key' y valor '$value'");

    Map<String, String> data = {
      key: value,
    };

    try {
      await _operadorProvider.update(data, widget.operador.id);
      _showSnackBar(context, 'Actualizacion exitosa');
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

    if (widget.operador.verificacionStatus == "registrado") {
      statusText = 'Registrado';
    }
    else if (widget.operador.verificacionStatus == 'activado') {
      statusText = 'Activado';
    }
    else if (widget.operador.verificacionStatus == 'bloqueado') {
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
