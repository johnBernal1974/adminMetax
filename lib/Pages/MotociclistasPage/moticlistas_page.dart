import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/main_layout.dart';
import '../../models/operador_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';
import '../DriverDetailPage/driver_detail_page.dart';



class MotociclistasPage extends StatefulWidget {
  const MotociclistasPage({super.key});

  @override
  State<MotociclistasPage> createState() => _MotociclistasPageState();
}

class _MotociclistasPageState extends State<MotociclistasPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String filterStatus = "";
  int totalDrivers = 0;
  Operador? operador;
  OperadorProvider _operadorProvider = OperadorProvider();
  MyAuthProvider _authProvider = MyAuthProvider();


  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final conductores = driverProvider.drivers;
    final isMobileOrTablet = MediaQuery.of(context).size.width <= 800;

    Color getStatusColor(driver) {
      if (driver.verificacionStatus == "registrado") {
        return Colors.blueGrey;
      } else if (driver.verificacionStatus == "foto_tomada") {
        return Colors.amber;
      } else if (driver.verificacionStatus == 'Procesando') {
        return Colors.blueAccent;
      } else if (driver.verificacionStatus == 'corregida') {
        return Colors.purple;
      } else if (driver.verificacionStatus == 'activado') {
        return Colors.green;
      } else if (driver.verificacionStatus == 'bloqueado') {
        return Colors.red.shade900;
      }else if (driver.verificacionStatus == 'bloqueo_AJ') {
        return Colors.deepOrange;
      }else if (driver.verificacionStatus == 'rechazada') {
        return Colors.brown.shade900;
      } else if (driver.verificacionStatus == 'suspendido') {
        return Colors.black;
      } else {
        return Colors.grey;
      }
    }

    List filteredConductores = conductores.where((driver) {
      bool matchesFilter = true;
      if (filterStatus.isNotEmpty) {
        switch (filterStatus) {
          case 'registrado':
            matchesFilter = driver.verificacionStatus == 'registrado';
            break;
          case 'foto_tomada':
            matchesFilter = driver.verificacionStatus == 'foto_tomada';
            break;
          case 'Procesando':
            matchesFilter = driver.verificacionStatus == 'Procesando';
            break;
          case 'corregida':
            matchesFilter = driver.verificacionStatus == 'corregida';
            break;
          case 'rechazada':
            matchesFilter = driver.verificacionStatus == 'rechazada';
            break;
          case 'activado':
            matchesFilter = driver.verificacionStatus == 'activado';
            break;
          case 'bloqueado':
            matchesFilter = driver.verificacionStatus == "bloqueado";
            break;

          case 'bloqueo_AJ':
            matchesFilter = driver.verificacionStatus == "bloqueo_AJ";
            break;
          case 'suspendido':
            matchesFilter = driver.the41SuspendidoPorCancelaciones == true;
            break;
        }
      }
      if (driver.rol.isNotEmpty) {
        matchesFilter = matchesFilter && driver.rol == "moto";
      }
      return matchesFilter &&
          (driver.the01Nombres.toLowerCase().contains(searchQuery.toLowerCase()) ||
              driver.the02Apellidos.toLowerCase().contains(searchQuery.toLowerCase()) ||
              driver.the03NumeroDocumento.toLowerCase().contains(searchQuery.toLowerCase()) ||
              driver.the06Email.toLowerCase().contains(searchQuery.toLowerCase()) ||
              driver.the18Placa.toLowerCase().contains(searchQuery.toLowerCase()) ||
              driver.the07Celular.toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();
    totalDrivers = filteredConductores.length;

    int countByStatus(String status) {
      return conductores.where((driver) {
        bool matchesStatus = false;
        switch (status) {
          case 'registrado':
            matchesStatus = driver.verificacionStatus == 'registrado';
            break;
          case 'foto_tomada':
            matchesStatus = driver.verificacionStatus == 'foto_tomada';
            break;
          case 'Procesando':
            matchesStatus = driver.verificacionStatus == 'Procesando';
            break;

          case 'corregida':
            matchesStatus = driver.verificacionStatus == 'corregida';
            break;
          case 'rechazada':
            matchesStatus = driver.verificacionStatus == 'rechazada';
            break;
          case 'activado':
            matchesStatus = driver.verificacionStatus == 'activado';
            break;
          case 'bloqueado':
            matchesStatus = driver.verificacionStatus == 'bloqueado';
            break;
          case 'bloqueo_AJ':
            matchesStatus = driver.verificacionStatus == 'bloqueo_AJ';
            break;
          case 'suspendido':
            matchesStatus = driver.the41SuspendidoPorCancelaciones == true;
            break;
        }

        bool matchesRole = true;
        if (status.isNotEmpty) {
          if (driver.rol.isNotEmpty) {
            matchesRole = driver.rol == "moto";
          }
        }

        return matchesStatus && matchesRole;
      }).length;
    }

    return MainLayout(
      content: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top), // Espacio para la barra de estado en la parte superior
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                margin: const EdgeInsets.all(7),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth <= 600) {
                      return _buildMobileLayout(context, driverProvider, filteredConductores, countByStatus, getStatusColor);
                    } else {
                      return _buildDesktopLayout(context, driverProvider, filteredConductores, countByStatus, getStatusColor);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      pageTitle: 'Motociclistas',
    );
  }

  Widget _buildMobileLayout(BuildContext context, DriverProvider driverProvider, List filteredConductores, int Function(String) countByStatus, Color Function(dynamic) getStatusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Total de Motociclistas:\n$totalDrivers', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 20),
            IconButton(
              icon: Icon(Icons.refresh),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                driverProvider.fetchDrivers();
              },
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 20, thickness: 2),
        _buildSearchField(),
        const SizedBox(height: 30),
        _buildFilterButtons(true, countByStatus),
        const SizedBox(height: 10),
        _buildDriverTable(filteredConductores, getStatusColor),
      ],
    );
  }



  Widget _buildDesktopLayout(BuildContext context, DriverProvider driverProvider, List filteredConductores, int Function(String) countByStatus, Color Function(dynamic) getStatusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Total de Motociclistas:\n$totalDrivers', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 100),
            ElevatedButton(
              onPressed: () {
                driverProvider.fetchDrivers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Cargar motociclistas', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 20, thickness: 2),
        _buildSearchField(),
        const SizedBox(height: 30),
        _buildFilterButtons(false, countByStatus),
        const SizedBox(height: 10),
        _buildDriverTable(filteredConductores, getStatusColor),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 350,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Buscar motociclista',
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                searchQuery = searchController.text.trim();
              });
            },
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildFilterButtons(bool isMobile, int Function(String) countByStatus) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: [
        if (isMobile)
          ..._buildMobileFilterButtons(countByStatus)
        else
          ..._buildDesktopFilterButtons(countByStatus),
      ],
    );
  }
  List<Widget> _buildMobileFilterButtons(int Function(String) countByStatus) {
    return [
      IconButton(
        icon: Icon(Icons.account_circle, color: Colors.blueGrey),
        onPressed: () {
          setState(() {
            filterStatus = 'registrado';
          });
        },
        tooltip: 'Registrado (${countByStatus('registrado')})',
      ),
      IconButton(
        icon: Icon(Icons.photo_camera, color: Colors.amber),
        onPressed: () {
          setState(() {
            filterStatus = 'foto_tomada';
          });
        },
        tooltip: 'Doc. Faltantes (${countByStatus('foto_tomada')})',
      ),
      IconButton(
        icon: Icon(Icons.pending, color: Colors.blueAccent),
        onPressed: () {
          setState(() {
            filterStatus = 'Procesando';
          });
        },
        tooltip: 'Procesando (${countByStatus('Procesando')})',
      ),
      IconButton(
        icon: Icon(Icons.check_circle, color: Colors.purple),
        onPressed: () {
          setState(() {
            filterStatus = 'corregida';
          });
        },
        tooltip: 'Corregida (${countByStatus('corregida')})',
      ),
      IconButton(
        icon: Icon(Icons.watch_later, color: Colors.brown.shade900),
        onPressed: () {
          setState(() {
            filterStatus = 'rechazada';
          });
        },
        tooltip: 'En espera (${countByStatus('rechazada')})',
      ),
      IconButton(
        icon: Icon(Icons.verified, color: Colors.green),
        onPressed: () {
          setState(() {
            filterStatus = 'activado';
          });
        },
        tooltip: 'Activado (${countByStatus('activado')})',
      ),
      IconButton(
        icon: Icon(Icons.block, color: Colors.red.shade900),
        onPressed: () {
          setState(() {
            filterStatus = 'bloqueado';
          });
        },
        tooltip: 'Bloqueado (${countByStatus('bloqueado')})',
      ),
      IconButton(
        icon: Icon(Icons.back_hand, color: Colors.deepOrange),
        onPressed: () {
          setState(() {
            filterStatus = 'bloqueo_AJ';
          });
        },
        tooltip: 'BloqueoAJ (${countByStatus('bloqueo_AJ')})',
      ),
      IconButton(
        icon: Icon(Icons.pause_circle_filled, color: Colors.black),
        onPressed: () {
          setState(() {
            filterStatus = 'suspendido';
          });
        },
        tooltip: 'Suspendido (${countByStatus('suspendido')})',
      ),
      IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () {
          setState(() {
            filterStatus = '';
            searchQuery = '';
          });
        },
        tooltip: 'Reset',
      ),
    ];
  }

  List<Widget> _buildDesktopFilterButtons(int Function(String) countByStatus) {
    return [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black, backgroundColor: Colors.blueGrey,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'registrado';
          });
        },
        child: Text('Registrado (${countByStatus('registrado')})', style: TextStyle(color: blanco)),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.amber,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'foto_tomada';
          });
        },
        child: Text('Doc. Faltantes (${countByStatus('foto_tomada')})', style: TextStyle(color: negro)),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'Procesando';
          });
        },
        child: Text('Procesando (${countByStatus('Procesando')})'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.purple,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'corregida';
          });
        },
        child: Text('Corregida (${countByStatus('corregida')})'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.brown.shade900,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'rechazada';
          });
        },
        child: Text('En espera (${countByStatus('rechazada')})'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.green,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'activado';
          });
        },
        child: Text('Activado (${countByStatus('activado')})'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.red.shade900,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'bloqueado';
          });
        },
        child: Text('Bloqueado (${countByStatus('bloqueado')})'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.deepOrange,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'bloqueo_AJ';
          });
        },
        child: Text('Bloqueo_AJ (${countByStatus('bloqueo_AJ')})'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.black,
          onPrimary: Colors.white,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'suspendido';
          });
        },
        child: Text('Suspendido (${countByStatus('suspendido')})'),
      ),
      IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () {
          setState(() {
            filterStatus = '';
            searchQuery = '';
          });
        },
        tooltip: 'Reset',
      ),
    ];
  }

  Widget _buildDriverTable(List filteredConductores, Color Function(dynamic) getStatusColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 20.0,
          headingRowHeight: 56.0,
          dataRowHeight: 70.0,
          columns: const [
            DataColumn(
              label: Text(
                'Estado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Imagen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Nombre',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Apellidos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Identificación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Correo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Placa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Celular',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Acción',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: filteredConductores.map((driver) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: getStatusColor(driver),
                    ),
                  ),
                ),
                DataCell(
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: driver.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),
                DataCell(Text(
                  driver.the01Nombres ?? "Nombre no disponible",
                  style: TextStyle(color: Colors.black),
                )),
                DataCell(Text(
                  driver.the02Apellidos ?? "Apellidos no disponibles",
                  style: TextStyle(color: Colors.black),
                )),
                DataCell(Text(driver.the03NumeroDocumento ?? "Documento no disponible")),
                DataCell(Text(driver.the06Email ?? "Email no disponible")),
                DataCell(Text(driver.the18Placa ?? "Placa no disponible")),
                DataCell(Text(driver.the07Celular ?? "Celular no disponible")),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.double_arrow_outlined, color: negro),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverDetailPage(driver: driver),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
