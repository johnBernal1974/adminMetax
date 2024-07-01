
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../common/main_layout.dart';
import '../../models/prices_model.dart';
import '../../providers/prices_provider.dart';

class PricesPage extends StatefulWidget {
  PricesPage({Key? key}) : super(key: key);

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  final PricesProvider _pricesProvider = PricesProvider();
  late Price _priceData ; // Objeto para almacenar los datos de precio
  TextEditingController _dinamicaController = TextEditingController();

  String? selectedMantenimientoConductores;
  String? selectedMantenimientoUsuarios;
  double? selectedDinamica;

  @override
  void initState() {
    super.initState();
    _loadPriceData();
    selectedMantenimientoConductores = _priceData.theMantenimientoConductores;
    selectedMantenimientoUsuarios = _priceData.theMantenimientoUsuarios;
    selectedDinamica = _priceData.theDinamica;

  }

  Future<void> _loadPriceData() async {
    try {
      Price price = await _pricesProvider.getAll(); // Obtener todos los precios
      setState(() {
        _priceData = price;
      });
    } catch (e) {
      print('Error al cargar los datos de precio: $e');
      // Manejar el error según sea necesario
    }
  }

  // Método para convertir booleanos en "SI" o "NO"
  String boolToYesNo(bool value) {
    return value ? 'SI' : 'NO';
  }

  @override
  Widget build(BuildContext context) {
    selectedMantenimientoConductores = _priceData.theMantenimientoConductores;
    selectedMantenimientoUsuarios = _priceData.theMantenimientoUsuarios;
    selectedDinamica = _priceData.theDinamica;
    return MainLayout(
      pageTitle:  "Configuraciones",
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
                          _seccionConfiguracion(),
                          const Divider(),
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
              "Configuraciones",
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        );
      },
    );
  }


  Widget _seccionConfiguracion(){
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
                  Column(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                const Text("Info de contacto", style: TextStyle(fontWeight: FontWeight.bold),),
                                _buildTextField(_priceData.theCorreoConductores.toString(), 'Etiqueta del Precio', "clave_del_precio"),
                                _buildTextField( _priceData.theCorreoUsuarios.toString(), 'Correo para Clientes', "correo_usuarios"),
                                _buildTextField(_priceData.theCelularAtencionConductores.toString(), 'Celular para Conductores', "celular_atencion_conductores"),
                                _buildTextField(_priceData.theCelularAtencionUsuarios.toString(), 'Celular para Clientes', "celular_atencion_usuarios"),
                                _buildTextField(_priceData.theLinkCancelarCuenta.toString(), 'Link cancelación cuenta', "link_cancelar_cuenta"),
                                _buildTextField(_priceData.theLinkPoliticasPrivacidad.toString(), 'Link Políticas de privacidad', "link_politicas_privacidad"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(),// Espacio entre columnas
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                const Text("Tarifas", style: TextStyle(fontWeight: FontWeight.bold),),
                                _buildTextFieldEnteros(_priceData.theTarifaAeropuerto.toString(),"Aeropuerto", "tarifa_aeropuerto"),
                                _buildTextFieldEnteros(_priceData.theTarifaMinimaHotel.toString(), 'Mínima hotel', "tarifa_minima_hotel"),
                                _buildTextFieldEnteros(_priceData.theTarifaMinimaRegular.toString(), 'Mínima regular', "tarifa_minima_regular"),
                                _buildTextFieldEnteros(_priceData.theTarifaMinimaTurismo.toString(), 'Mínima turismo', "tarifa_minima_turismo"),
                                _buildTextFieldEnteros(_priceData.theDistanciaTarifaMinima.toString(), 'Distancia tarifa mínima', "distancia_tarifa_minima"),
                                _buildTextFieldEnteros(_priceData.theComision.toString(), 'Comisión %', "comision"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(),// Espacio entre columnas
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                const Text("Versiones", style: TextStyle(fontWeight: FontWeight.bold),),
                                _buildTextField(_priceData.theVersionConductorAndroid.toString(), 'Conductor android', "version_conductor_android"),
                                _buildTextField(_priceData.theVersionUsuarioAndroid.toString(), 'Usuario android', "version_usuario_android"),
                                _buildTextField(_priceData.theVersionusuarioIos.toString(), 'Usuario IOS', "version_usuario_ios"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),// Espacio entre columnas
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                const Text("Valores kilometro", style: TextStyle(fontWeight: FontWeight.bold),),
                                _buildTextFieldEnteros(_priceData.theValorKmHotel.toString(), '\$Km Hotel', "valor_km_hotel"),
                                _buildTextFieldEnteros(_priceData.theValorKmRegular.toString(), '\$Km Regular', "valor_km_regular"),
                                _buildTextFieldEnteros(_priceData.theValorKmTurismo.toString(), '\$Km Turismo', "valor_km_turismo"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),// Espacio entre columnas
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                const Text("Valores Minuto", style: TextStyle(fontWeight: FontWeight.bold),),
                                _buildTextFieldEnteros(_priceData.theValorMinHotel.toString(), '\$Min Hotel', "valor_min_hotel"),
                                _buildTextFieldEnteros(_priceData.theValorMinRegular.toString(), '\$Min Regular', "valor_min_regular"),
                                _buildTextFieldEnteros(_priceData.theValorMinTurismo.toString(), '\$Min Turismo', "valor_min_turismo"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),// Espacio entre columnas
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                const Text("Adicionales", style: TextStyle(fontWeight: FontWeight.bold),),
                                _buildTextFieldEnteros(_priceData.theValorAdicionalMaps.toString(), 'Adicional Maps', "valor_adicional_maps"),
                                _buildTextFieldEnteros(_priceData.theValorIva.toString(), 'Iva', "valor_Iva"),
                                _dropDinamica(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),// Espacio entre columnas
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                const Text("Valores cancelaciones", style: TextStyle(fontWeight: FontWeight.bold),),
                                _buildTextFieldEnteros(_priceData.theNumeroCancelacionesConductor.toString(), 'Max cancelaciones conductor', "numero_cancelaciones_conductor"),
                                _buildTextFieldEnteros(_priceData.theNumeroCancelacionesUsuario.toString(), 'Max cancelaciones usuario', "numero_cancelaciones_usuario"),
                                _buildTextFieldEnteros(_priceData.theTiempoDeBloqueo.toString(), 'Tiempo de bloqueo', "tiempo_de_bloqueo"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),// Espacio entre columnas
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                const Text("Mantenimiento", style: TextStyle(fontWeight: FontWeight.bold),),
                                _dropMantenimientoConductores(),
                                _dropMantenimientoUsuarios()

                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),// Espacio entre columnas
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                const Text("Varios", style: TextStyle(fontWeight: FontWeight.bold),),
                                _buildTextFieldEnteros(_priceData.theRadioDeBusqueda.toString(), 'Radio de búsqueda', "radio_de_busqueda"),
                                _buildTextFieldEnteros(_priceData.theTiempoDeEspera.toString(), 'Tiempo de espera', "tiempo_de_espera"),
                                _buildTextFieldEnteros(_priceData.theRecargaInicial.toString(), 'Recarga inicial', "recarga_Inicial"),
                              ],
                            ),

                          ],
                        ),

                      ],
                    ),

                ],
              ) : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                      children: [
                        const SizedBox(height: 50),// Espacio entre columnas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Text("Info de contacto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                  _buildTextField(_priceData.theCorreoConductores.toString(), 'Etiqueta del Precio', "clave_del_precio"),
                                  _buildTextField( _priceData.theCorreoUsuarios.toString(), 'Correo para Clientes', "correo_usuarios"),
                                  _buildTextField(_priceData.theCelularAtencionConductores.toString(), 'Celular para Conductores', "celular_atencion_conductores"),
                                  _buildTextField(_priceData.theCelularAtencionUsuarios.toString(), 'Celular para Clientes', "celular_atencion_usuarios"),
                                  _buildTextField(_priceData.theLinkCancelarCuenta.toString(), 'Link cancelación cuenta', "link_cancelar_cuenta"),
                                  _buildTextField(_priceData.theLinkPoliticasPrivacidad.toString(), 'Link Políticas de privacidad', "link_politicas_privacidad"),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            Expanded(
                              child: Column(
                                children: [
                                  const Text("Tarifas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                  _buildTextFieldEnteros(_priceData.theTarifaAeropuerto.toString(),"Aeropuerto", "tarifa_aeropuerto"),
                                  _buildTextFieldEnteros(_priceData.theTarifaMinimaHotel.toString(), 'Mínima hotel', "tarifa_minima_hotel"),
                                  _buildTextFieldEnteros(_priceData.theTarifaMinimaRegular.toString(), 'Mínima regular', "tarifa_minima_regular"),
                                  _buildTextFieldEnteros(_priceData.theTarifaMinimaTurismo.toString(), 'Mínima turismo', "tarifa_minima_turismo"),
                                  _buildTextFieldEnteros(_priceData.theDistanciaTarifaMinima.toString(), 'Distancia tarifa mínima', "distancia_tarifa_minima"),
                                  _buildTextFieldEnteros(_priceData.theComision.toString(), 'Comisión %', "comision"),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),// Espacio entre columnas
                            Expanded(
                              child: Column(
                                children: [
                                  const Text("Versiones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                  _buildTextField(_priceData.theVersionConductorAndroid.toString(), 'Conductor android', "version_conductor_android"),
                                  _buildTextField(_priceData.theVersionUsuarioAndroid.toString(), 'Usuario android', "version_usuario_android"),
                                  _buildTextField(_priceData.theVersionusuarioIos.toString(), 'Usuario IOS', "version_usuario_ios"),

                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 50),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Text("Valores kilómetro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                  _buildTextFieldEnteros(_priceData.theValorKmHotel.toString(), '\$Km Hotel', "valor_km_hotel"),
                                  _buildTextFieldEnteros(_priceData.theValorKmRegular.toString(), '\$Km Regular', "valor_km_regular"),
                                  _buildTextFieldEnteros(_priceData.theValorKmTurismo.toString(), '\$Km Turismo', "valor_km_turismo"),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            Expanded(
                              child: Column(
                                children: [
                                  const Text("Valores Minuto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                  _buildTextFieldEnteros(_priceData.theValorMinHotel.toString(), '\$Min Hotel', "valor_min_hotel"),
                                  _buildTextFieldEnteros(_priceData.theValorMinRegular.toString(), '\$Min Regular', "valor_min_regular"),
                                  _buildTextFieldEnteros(_priceData.theValorMinTurismo.toString(), '\$Min Turismo', "valor_min_turismo"),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),// Espacio entre columnas
                            Expanded(
                              child: Column(
                                children: [
                                  const Text("Adicionales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                  _buildTextFieldEnteros(_priceData.theValorAdicionalMaps.toString(), 'Adicional Maps', "valor_adicional_maps"),
                                  _buildTextFieldEnteros(_priceData.theValorIva.toString(), 'Iva', "valor_Iva"),
                                  _dropDinamica(),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 50),// Espacio entre columnas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Text("Valores cancelaciones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                  _buildTextFieldEnteros(_priceData.theNumeroCancelacionesConductor.toString(), 'Max cancelaciones conductor', "numero_cancelaciones_conductor"),
                                  _buildTextFieldEnteros(_priceData.theNumeroCancelacionesUsuario.toString(), 'Max cancelaciones usuario', "numero_cancelaciones_usuario"),
                                  _buildTextFieldEnteros(_priceData.theTiempoDeBloqueo.toString(), 'Tiempo de bloqueo', "tiempo_de_bloqueo"),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            Expanded(
                              child: Column(
                                children: [
                                  const Text("Mantenimiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                  _dropMantenimientoConductores(),
                                  _dropMantenimientoUsuarios()
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),// Espacio entre columnas
                            Expanded(
                              child: Column(
                                children: [
                                  const Text("Varios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                  _buildTextFieldEnteros(_priceData.theRadioDeBusqueda.toString(), 'Radio de búsqueda', "radio_de_busqueda"),
                                  _buildTextFieldEnteros(_priceData.theTiempoDeEspera.toString(), 'Tiempo de espera', "tiempo_de_espera"),
                                  _buildTextFieldEnteros(_priceData.theRecargaInicial.toString(), 'Recarga inicial', "recarga_Inicial"),
                                  const SizedBox(height: 50),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                ],
              ),
            ],
          );
        }
    );
  }

  Widget _dropMantenimientoConductores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mantenimiento Conductores', style: TextStyle(fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedMantenimientoConductores,
                items: const [
                  DropdownMenuItem(value: "", child: Text("")),
                  DropdownMenuItem(value: "Si", child: Text("Si")),
                  DropdownMenuItem(value: "No", child: Text("No")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedMantenimientoConductores = value;
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
                if (selectedMantenimientoConductores != null && selectedMantenimientoConductores!.isNotEmpty) {
                  _saveField("mantenimiento_conductores", selectedMantenimientoConductores!, () {
                    setState(() {
                      // Actualizar el estado si es necesario
                    });
                  });
                } else {
                  _showSnackBar(context, 'Por favor seleccione una opción');
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _dropMantenimientoUsuarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mantenimiento Usuarios', style: TextStyle(fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedMantenimientoUsuarios,
                items: const [
                  DropdownMenuItem(value: "", child: Text("")),
                  DropdownMenuItem(value: "Si", child: Text("Si")),
                  DropdownMenuItem(value: "No", child: Text("No")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedMantenimientoUsuarios = value;
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
                if (selectedMantenimientoUsuarios != null && selectedMantenimientoUsuarios!.isNotEmpty) {
                  _saveField("mantenimiento_usuarios", selectedMantenimientoUsuarios!, () {
                    setState(() {
                      // Actualizar el estado si es necesario
                    });
                  });
                } else {
                  _showSnackBar(context, 'Por favor seleccione una opción');
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _dropDinamica() {
    List<double> dinamicaOptions = [
      1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2, 2.1, 2.2, 2.3, 2.4, 2.5, 3
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dinamica', style: TextStyle(fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dinamicaController,
                readOnly: true,
                decoration: InputDecoration(
                  suffixIcon: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: selectedDinamica,
                      items: dinamicaOptions.map((double value) {
                        return DropdownMenuItem<double>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (newValue) async {
                        setState(() {
                          selectedDinamica = newValue;
                          _dinamicaController.text = newValue.toString();
                        });
                        // try {
                        //   await _pricesProvider.updatePrice('dinamica', newValue);
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //       SnackBar(content: Text('Campo guardado exitosamente con key: dinamica y valor: $newValue'))
                        //   );
                        // } catch (error) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //       SnackBar(content: Text('Error al guardar campo con key: dinamica y valor: $newValue'))
                        //   );
                        // }
                      },
                    ),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () async {
                try {
                  await _pricesProvider.updatePrice('dinamica', selectedDinamica);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Campo guardado exitosamente con key: dinamica y valor: $selectedDinamica'))
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar campo con key: dinamica y valor: $selectedDinamica'))
                  );
                }
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
            icon: const Icon(Icons.save),
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

  Widget _buildTextFieldEnteros(String initialValue, String label, String key) {
    TextEditingController controller = TextEditingController(text: initialValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number, // Asegura que el teclado sea numérico
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              int? value = int.tryParse(controller.text); // Intentar convertir el texto a int
              if (value != null) {
                try {
                  await _saveFieldEnteros(key, controller.text); // Llama a tu método de actualización de precio
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Campo guardado exitosamente con key: $key y valor: $value')),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar campo con key: $key y valor: $value')),
                  );
                }
              } else {
                // Manejar el error de conversión
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Por favor, introduce un número válido')),
                );
              }
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> _saveFieldEnteros(String key, String value) async {
    try {
      await FirebaseFirestore.instance
          .collection('Prices')
          .doc("info")
          .update({key: int.parse(value)});
      print('Campo guardado exitosamente con key: $key y valor: $value');
    } catch (error) {
      print('Error al guardar campo con key: $key y valor: $value. Error: $error');
      throw error;
    }
  }



  void _saveField(String key, dynamic value, Function updateStateCallback) async {
    print("Guardando campo con key '$key' y valor '$value'");

    try {
      await _pricesProvider.updatePrice(key, value);
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


}
