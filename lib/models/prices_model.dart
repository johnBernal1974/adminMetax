
import 'dart:convert';

Price PriceFromJson(String str) => Price.fromJson(json.decode(str));

String PriceToJson(Price data) => json.encode(data.toJson());

class Price {
  String theCorreoConductores;
  String theCorreoUsuarios;
  String theCelularAtencionConductores;
  String theCelularAtencionUsuarios;
  String theLinkCancelarCuenta;
  String theLinkPoliticasPrivacidad;
  String theVersionConductorAndroid;
  String theVersionUsuarioAndroid;
  String theVersionusuarioIos;
  String theMantenimientoConductores;
  String theMantenimientoUsuarios;
  int  theComision;
  int theDistanciaTarifaMinima;
  int theNumeroCancelacionesConductor;
  int theNumeroCancelacionesUsuario;
  int theRadioDeBusqueda;
  int theRecargaInicial;
  int theTarifaAeropuerto;
  int theTarifaMinimaRegular;
  int theTarifaMinimaHotel;
  int theTarifaMinimaTurismo;
  int theTiempoDeBloqueo;
  int theTiempoDeEspera;
  int theValorAdicionalMaps;
  int theValorIva;
  int theValorKmHotel;
  int theValorKmRegular;
  int theValorKmTurismo;
  int theValorMinHotel;
  int theValorMinRegular;
  int theValorMinTurismo;
  double theDinamica;


  Price({
    required this.theCorreoConductores,
    required this.theCorreoUsuarios,
    required this.theCelularAtencionConductores,
    required this.theCelularAtencionUsuarios,
    required this.theLinkCancelarCuenta,
    required this.theLinkPoliticasPrivacidad,
    required this.theVersionConductorAndroid,
    required this.theVersionUsuarioAndroid,
    required this.theVersionusuarioIos,
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
    required this.theTarifaMinimaHotel,
    required this.theTarifaMinimaTurismo,
    required this.theTiempoDeBloqueo,
    required this.theTiempoDeEspera,
    required this.theValorAdicionalMaps,
    required this.theValorIva,
    required this.theValorKmHotel,
    required this.theValorKmRegular,
    required this.theValorKmTurismo,
    required this.theValorMinHotel,
    required this.theValorMinRegular,
    required this.theValorMinTurismo,
    required this.theDinamica,


  });

  factory Price.fromJson(Map<String, dynamic> json) => Price(
      theCorreoConductores: json["correo_conductores"]  ?? '',
      theCorreoUsuarios: json["correo_usuarios"]  ?? '',
      theCelularAtencionConductores: json["celular_atencion_conductores"]  ?? '',
      theCelularAtencionUsuarios: json["celular_atencion_usuarios"]  ?? '',
      theLinkCancelarCuenta: json["link_cancelar_cuenta"]  ?? '',
      theLinkPoliticasPrivacidad: json["link_politicas_privacidad"]  ?? '',
      theVersionConductorAndroid: json["version_conductor_android"]  ?? '',
      theVersionUsuarioAndroid: json["version_usuario_android"]  ?? '',
      theVersionusuarioIos: json["version_usuario_ios"]  ?? '',
      theMantenimientoConductores: json["mantenimiento_conductores"]  ?? '',
      theMantenimientoUsuarios: json["mantenimiento_usuarios"]  ?? '',
      theComision: json["comision"]  ?? '',
      theDistanciaTarifaMinima: json["distancia_tarifa_minima"]  ?? '',
      theNumeroCancelacionesConductor: json["numero_cancelaciones_conductor"]  ?? '',
      theNumeroCancelacionesUsuario: json["numero_cancelaciones_usuario"]  ?? '',
      theRadioDeBusqueda: json["radio_de_busqueda"]  ?? '',
      theRecargaInicial: json["recarga_Inicial"]  ?? '',
      theTarifaAeropuerto: json["tarifa_aeropuerto"]  ?? '',
      theTarifaMinimaRegular: json["tarifa_minima_regular"]?? '',
      theTarifaMinimaHotel: json["tarifa_minima_hotel"]  ?? '',
      theTarifaMinimaTurismo: json["tarifa_minima_turismo"]  ?? '',
      theTiempoDeBloqueo: json["tiempo_de_bloqueo"]  ?? '',
      theTiempoDeEspera: json["tiempo_de_espera"]  ?? '',
      theValorAdicionalMaps: json["valor_adicional_maps"]  ?? '',
      theValorIva: json["valor_Iva"]  ?? '',
      theValorKmHotel: json["valor_km_hotel"]  ?? '',
      theValorKmRegular: json["valor_km_regular"]  ?? '',
      theValorKmTurismo: json["valor_km_turismo"]  ?? '',
      theValorMinHotel: json["valor_min_hotel"]  ?? '',
      theValorMinRegular: json["valor_min_regular"] ?? "",
      theValorMinTurismo: json["valor_min_turismo"] ?? "",
      theDinamica: json["dinamica"]?.toDouble() ?? "",
  );

  Map<String, dynamic> toJson() => {
    "Correo_conductores": theCorreoConductores,
    "correo_usuarios": theCorreoUsuarios,
    "celular_atencion_conductores": theCelularAtencionConductores,
    "celular_atencion_usuarios": theCelularAtencionUsuarios,
    "link_cancelar_cuenta": theLinkCancelarCuenta,
    "link_politicas_privacidad": theLinkPoliticasPrivacidad,
    "version_conductor_android": theVersionConductorAndroid,
    "version_usuario_android": theVersionUsuarioAndroid,
    "version_usuario_ios": theVersionusuarioIos,
    "mantenimiento_conductores": theMantenimientoConductores,
    "mantenimiento_usuarios": theMantenimientoUsuarios,
    "comision": theComision,
    "distancia_tarifa_minima": theDistanciaTarifaMinima,
    "numero_cancelaciones_conductor": theNumeroCancelacionesConductor,
    "numero_cancelaciones_usuario": theNumeroCancelacionesUsuario,
    "radio_de_busqueda": theRadioDeBusqueda,
    "recarga_Inicial": theRecargaInicial,
    "tarifa_aeropuerto": theTarifaAeropuerto,
    "tarifa_minima_regular": theTarifaMinimaRegular,
    "tarifa_minima_hotel": theTarifaMinimaHotel,
    "tarifa_minima_turismo": theTarifaMinimaTurismo,
    "tiempo_de_bloqueo": theTiempoDeBloqueo,
    "tiempo_de_espera": theTiempoDeEspera,
    "valor_adicional_maps": theValorAdicionalMaps,
    "valor_Iva": theValorIva,
    "valor_km_hotel": theValorKmHotel,
    "valor_km_regular": theValorKmRegular,
    "valor_km_turismo": theValorKmTurismo,
    "valor_min_hotel": theValorMinHotel,
    "valor_min_regular": theValorMinRegular,
    "valor_min_turismo": theValorMinTurismo,
    "dinamica": theDinamica,
  };
}
