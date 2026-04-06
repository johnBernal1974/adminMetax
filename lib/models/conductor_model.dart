import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

Driver driverFromJson(String str) => Driver.fromJson(json.decode(str));

String driverToJson(Driver data) => json.encode(data.toJson());

class Driver {
  String id;
  String rol;
  String the01Nombres;
  String the02Apellidos;
  String the03NumeroDocumento;
  String the04TipoDocumento;
  String the05FechaExpedicionDocumento;
  String the06Email;
  String the07Celular;
  String the08FechaNacimiento;
  String the09Genero;
  Timestamp? the10FechaRegistroTimestamp;
  bool the11EstaActivado;
  String the12FechaActivacion;
  String the13NombreActivador;

  String the25CedulaDelanteraFoto;
  String the26CedulaTraseraFoto;
  String the29FotoPerfil;
  int the30NumeroViajes;
  double the31Calificacion;
  int the321SaldoAnteriorInfo;
  int the32SaldoRecarga;
  String the33FechaUltimaRecarga;
  int the34NuevaRecarga;
  String the35NuevaRecargaInfo;
  String the36FechaNuevaRecarga;
  int the37RecargaRedimir;
  bool the38EstaBloqueado;
  bool the39EstaConectado;
  bool the00_is_working;
  bool the00_is_active;
  int the40NumeroCancelaciones;
  bool the41SuspendidoPorCancelaciones;
  String token;
  String image;
  String fotoCedulaDelantera;
  String fotoCedulaTrasera;
  String verificacionStatus;
  String the00_ultimo_cliente;
  bool ceduladelanteraTomada;
  bool cedulatraseraTomada;
  String licenciaCategoria;
  String licenciaVigencia;
  bool fotoPerfilTomada;

  String vehiculoActivoId;
  String placaActiva;

  Driver({
    required this.id,
    required this.rol,
    required this.the01Nombres,
    required this.the02Apellidos,
    required this.the03NumeroDocumento,
    required this.the04TipoDocumento,
    required this.the05FechaExpedicionDocumento,
    required this.the06Email,
    required this.the07Celular,
    required this.the08FechaNacimiento,
    required this.the09Genero,
    required this.the10FechaRegistroTimestamp,
    required this.the11EstaActivado,
    required this.the12FechaActivacion,
    required this.the13NombreActivador,
    required this.the25CedulaDelanteraFoto,
    required this.the26CedulaTraseraFoto,
    required this.the29FotoPerfil,
    required this.the30NumeroViajes,
    required this.the31Calificacion,
    required this.the321SaldoAnteriorInfo,
    required this.the32SaldoRecarga,
    required this.the33FechaUltimaRecarga,
    required this.the34NuevaRecarga,
    required this.the35NuevaRecargaInfo,
    required this.the36FechaNuevaRecarga,
    required this.the37RecargaRedimir,
    required this.the38EstaBloqueado,
    required this.the39EstaConectado,
    required this.the40NumeroCancelaciones,
    required this.the41SuspendidoPorCancelaciones,
    required this.token,
    required this.image,
    required this.fotoCedulaDelantera,
    required this.fotoCedulaTrasera,
    required this.verificacionStatus,
    required this.the00_is_working,
    required this.the00_is_active,
    required this.the00_ultimo_cliente,
    required this.ceduladelanteraTomada,
    required this.cedulatraseraTomada,
    required this.licenciaCategoria,
    required this.licenciaVigencia,
    required this.fotoPerfilTomada,
    required this.vehiculoActivoId,
    required this.placaActiva,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver (
    id: json["id"],
    rol: json["rol"],
    the01Nombres: json["01_Nombres"],
    the02Apellidos: json["02_Apellidos"],
    the03NumeroDocumento: json["03_Numero_Documento"],
    the04TipoDocumento: json["04_Tipo_Documento"],
    the05FechaExpedicionDocumento: json["05_Fecha_Expedicion_Documento"],
    the06Email: json["06_Email"],
    the07Celular: json["07_Celular"],
    the08FechaNacimiento: json["08_Fecha_Nacimiento"],
    the09Genero: json["09_Genero"],
      the10FechaRegistroTimestamp:
      json["10_Fecha_Registro_Timestamp"] is Timestamp
          ? json["10_Fecha_Registro_Timestamp"]
          : null,
    the11EstaActivado: json["11_Esta_activado"],
    the12FechaActivacion: json["12_Fecha_Activacion"],
    the13NombreActivador: json["13_Nombre_Activador"],
    the25CedulaDelanteraFoto: json["25_Cedula_Delantera_foto"],
    the26CedulaTraseraFoto: json["26_Cedula_Trasera_foto"],
    the29FotoPerfil: json["29_Foto_perfil"],
    the30NumeroViajes: json["30_Numero_viajes"] ?? 0,
    the31Calificacion: (json["31_Calificacion"] ?? 0).toDouble(),
    the321SaldoAnteriorInfo: json["321_Saldo_Anterior_Info"],
    the32SaldoRecarga: json["32_Saldo_Recarga"] ?? 0,
    the33FechaUltimaRecarga: json["33_Fecha_Ultima_Recarga"],
    the34NuevaRecarga: json["34_Nueva_Recarga"],
    the35NuevaRecargaInfo: json["35_Nueva_Recarga_Info"],
    the36FechaNuevaRecarga: json["36_Fecha_Nueva_Recarga"],
    the37RecargaRedimir: json["37_Recarga_Redimir"],
    the38EstaBloqueado: json["38_Esta_bloqueado"],
    the39EstaConectado: json["39_Esta_conectado"],
    the40NumeroCancelaciones: json["40_Numero_Cancelaciones"],
    the41SuspendidoPorCancelaciones: json["41_Suspendido_Por_Cancelaciones"],
    token: json["token"],
    image: json["image"],
    fotoCedulaDelantera: json["foto_cedula_delantera"] ?? '',
    fotoCedulaTrasera: json["foto_cedula_trasera"] ?? '',
    verificacionStatus: json["Verificacion_Status"] ?? '',
    the00_is_active: json["00_is_active"] ?? false,
    the00_is_working: json["00_is_working"] ?? false,
    the00_ultimo_cliente: json["00_ultimo_cliente"] ?? '',
    ceduladelanteraTomada: json["cedula_delantera_tomada"] ?? false,
    cedulatraseraTomada: json["cedula_trasera_tomada"] ?? false,
    licenciaCategoria: json["licencia_categoria"] ?? '',
    licenciaVigencia: json["licencia_vigencia"] ?? '',
    fotoPerfilTomada: json["foto_perfil_tomada"] ?? false,
    vehiculoActivoId: json["vehiculoActivoId"] ?? '',
    placaActiva: json["placaActiva"] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "rol": rol,
    "01_Nombres": the01Nombres,
    "02_Apellidos": the02Apellidos,
    "03_Numero_Documento": the03NumeroDocumento,
    "04_Tipo_Documento": the04TipoDocumento,
    "05_Fecha_Expedicion_Documento": the05FechaExpedicionDocumento,
    "06_Email": the06Email,
    "07_Celular": the07Celular,
    "08_Fecha_Nacimiento": the08FechaNacimiento,
    "09_Genero": the09Genero,
    "10_Fecha_Registro_Timestamp": the10FechaRegistroTimestamp,
    "11_Esta_activado": the11EstaActivado,
    "12_Fecha_Activacion": the12FechaActivacion,
    "13_Nombre_Activador": the13NombreActivador,
    "25_Cedula_Delantera_foto": the25CedulaDelanteraFoto,
    "26_Cedula_Trasera_foto": the26CedulaTraseraFoto,
    "29_Foto_perfil": the29FotoPerfil,
    "30_Numero_viajes": the30NumeroViajes,
    "31_Calificacion": the31Calificacion,
    "321_Saldo_Anterior_Info": the321SaldoAnteriorInfo,
    "32_Saldo_Recarga": the32SaldoRecarga,
    "33_Fecha_Ultima_Recarga": the33FechaUltimaRecarga,
    "34_Nueva_Recarga": the34NuevaRecarga,
    "35_Nueva_Recarga_Info": the35NuevaRecargaInfo,
    "36_Fecha_Nueva_Recarga": the36FechaNuevaRecarga,
    "37_Recarga_Redimir": the37RecargaRedimir,
    "38_Esta_bloqueado": the38EstaBloqueado,
    "39_Esta_conectado": the39EstaConectado,
    "40_Numero_Cancelaciones": the40NumeroCancelaciones,
    "41_Suspendido_Por_Cancelaciones": the41SuspendidoPorCancelaciones,
    "token": token,
    "image": image,
    "foto_cedula_delantera": fotoCedulaDelantera,
    "foto_cedula_trasera": fotoCedulaTrasera,
    "Verificacion_Status": verificacionStatus,
    "00_is_active": the00_is_active,
    "00_is_working": the00_is_working,
    "00_ultimo_cliente": the00_ultimo_cliente,
    "cedula_delantera_tomada": ceduladelanteraTomada,
    "cedula_trasera_tomada": cedulatraseraTomada,
    "licencia_categoria": licenciaCategoria,
    "licencia_vigencia": licenciaVigencia,
    "foto_perfil_tomada": fotoPerfilTomada,
    "vehiculoActivoId": vehiculoActivoId,
    "placaActiva": placaActiva,
  };
}