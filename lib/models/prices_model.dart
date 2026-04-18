import 'dart:convert';

Price priceFromJson(String str) => Price.fromJson(json.decode(str));

String priceToJson(Price data) => json.encode(data.toJson());

class Price {
  String theCorreoConductores;
  String theCorreoUsuarios;
  String theCelularAtencionConductores;
  String theCelularAtencionUsuarios;
  String theLinkCancelarCuenta;
  String theLinkPoliticasPrivacidad;
  String theMantenimientoConductores;
  String theMantenimientoUsuarios;
  int theComision;
  int theDistanciaTarifaMinima;
  int theNumeroCancelacionesConductor;
  int theNumeroCancelacionesUsuario;
  double theRadioDeBusqueda;
  int theRecargaInicial;
  int theTarifaAeropuerto;
  int theTarifaMinimaRegular;
  int theTiempoDeBloqueo;
  int theTiempoDeEspera;
  int theValorKmRegular;
  int theValorMinRegular;
  double theDinamica;

  Price({
    required this.theCorreoConductores,
    required this.theCorreoUsuarios,
    required this.theCelularAtencionConductores,
    required this.theCelularAtencionUsuarios,
    required this.theLinkCancelarCuenta,
    required this.theLinkPoliticasPrivacidad,
    required this.theMantenimientoConductores,
    required this.theMantenimientoUsuarios,
    required this.theComision,
    required this.theDistanciaTarifaMinima,
    required this.theNumeroCancelacionesConductor,
    required this.theNumeroCancelacionesUsuario,
    required this.theRadioDeBusqueda,
    required this.theRecargaInicial,
    required this.theTarifaAeropuerto,
    required this.theTarifaMinimaRegular,
    required this.theTiempoDeBloqueo,
    required this.theTiempoDeEspera,
    required this.theValorKmRegular,
    required this.theValorMinRegular,
    required this.theDinamica,
  });

  factory Price.fromJson(Map<String, dynamic> json) => Price(
    theCorreoConductores: json["correo_conductores"] ?? '',
    theCorreoUsuarios: json["correo_usuarios"] ?? '',
    theCelularAtencionConductores: json["celular_atencion_conductores"] ?? '',
    theCelularAtencionUsuarios: json["celular_atencion_usuarios"] ?? '',
    theLinkCancelarCuenta: json["link_cancelar_cuenta"] ?? '',
    theLinkPoliticasPrivacidad: json["link_politicas_privacidad"] ?? '',
    theMantenimientoConductores: json["mantenimiento_conductores"] ?? '',
    theMantenimientoUsuarios: json["mantenimiento_usuarios"] ?? '',
    theComision: json["comision"] ?? 0,
    theDistanciaTarifaMinima: json["distancia_tarifa_minima"] ?? 0,
    theNumeroCancelacionesConductor: json["numero_cancelaciones_conductor"] ?? 0,
    theNumeroCancelacionesUsuario: json["numero_cancelaciones_usuario"] ?? 0,
    theRadioDeBusqueda: json["radio_de_busqueda"] ?? 0,
    theRecargaInicial: json["recarga_inicial"] ?? 0,
    theTarifaAeropuerto: json["tarifa_aeropuerto"] ?? 0,
    theTarifaMinimaRegular: json["tarifa_minima_regular"] ?? 0,
    theTiempoDeBloqueo: json["tiempo_de_bloqueo"] ?? 0,
    theTiempoDeEspera: json["tiempo_de_espera"] ?? 0,
    theValorKmRegular: json["valor_km_regular"] ?? 0,
    theValorMinRegular: json["valor_min_regular"] ?? 0,
    theDinamica: (json["dinamica"] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "correo_conductores": theCorreoConductores,
    "correo_usuarios": theCorreoUsuarios,
    "celular_atencion_conductores": theCelularAtencionConductores,
    "celular_atencion_usuarios": theCelularAtencionUsuarios,
    "link_cancelar_cuenta": theLinkCancelarCuenta,
    "link_politicas_privacidad": theLinkPoliticasPrivacidad,
    "mantenimiento_conductores": theMantenimientoConductores,
    "mantenimiento_usuarios": theMantenimientoUsuarios,
    "comision": theComision,
    "distancia_tarifa_minima": theDistanciaTarifaMinima,
    "numero_cancelaciones_conductor": theNumeroCancelacionesConductor,
    "numero_cancelaciones_usuario": theNumeroCancelacionesUsuario,
    "radio_de_busqueda": theRadioDeBusqueda,
    "recarga_inicial": theRecargaInicial,
    "tarifa_aeropuerto": theTarifaAeropuerto,
    "tarifa_minima_regular": theTarifaMinimaRegular,
    "tiempo_de_bloqueo": theTiempoDeBloqueo,
    "tiempo_de_espera": theTiempoDeEspera,
    "valor_km_regular": theValorKmRegular,
    "valor_min_regular": theValorMinRegular,
    "dinamica": theDinamica,
  };
}
