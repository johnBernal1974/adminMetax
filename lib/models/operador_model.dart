
import 'dart:convert';

Operador operadorFromJson(String str) => Operador.fromJson(json.decode(str));

String operadorToJson(Operador data) => json.encode(data.toJson());

class Operador {
  String id;
  String the01Nombres;
  String the02Apellidos;
  String the04NumeroDocumento;
  String the05TipoDocumento;
  String the06Email;
  String the07Celular;
  String the11FechaActivacion;
  String the12NombreActivador;
  String the20Rol;
  String image;
  String verificacionStatus;

  Operador({
    required this.id,
    required this.the01Nombres,
    required this.the02Apellidos,
    required this.the04NumeroDocumento,
    required this.the05TipoDocumento,
    required this.the06Email,
    required this.the07Celular,
    required this.the11FechaActivacion,
    required this.the12NombreActivador,
    required this.the20Rol,
    required this.image,
    required this.verificacionStatus,



  });

  factory Operador.fromJson(Map<String, dynamic> json) => Operador(
      id: json["id"] ?? '',
      the01Nombres: json["01_Nombres"]  ?? '',
      the02Apellidos: json["02_Apellidos"]  ?? '',
      the04NumeroDocumento: json["04_Numero_documento"]  ?? '',
      the05TipoDocumento: json["05_Tipo_documento"]  ?? '',
      the06Email: json["06_Email"]  ?? '',
      the07Celular: json["07_Celular"]  ?? '',
      the11FechaActivacion: json["11_Fecha_activacion"]  ?? '',
      the12NombreActivador: json["12_Nombre_activador"]  ?? '',
      the20Rol: json["20_Rol"]  ?? '',
      image: json["image"]  ?? '',
      verificacionStatus: json["Verificacion_Status"]  ?? '',

  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "01_Nombres": the01Nombres,
    "02_Apellidos": the02Apellidos,
    "04_Numero_documento": the04NumeroDocumento,
    "05_Tipo_documento": the05TipoDocumento,
    "06_Email": the06Email,
    "07_Celular": the07Celular,
    "11_Fecha_activacion": the11FechaActivacion,
    "12_Nombre_activador": the12NombreActivador,
    "20_Rol": the20Rol,
    "image": image,
    "Verificacion_Status": verificacionStatus,
  };
}