
import '../models/operador_model.dart';
import 'auth_provider.dart';
import 'operador_provider.dart'; // Importa tu proveedor de operador aquí

class OperadorService {
  final MyAuthProvider _authProvider;
  final OperadorProvider _operadorProvider;

  OperadorService(this._authProvider, this._operadorProvider);

  Future<Operador?> getOperadorInfo() async {
    String userId = _authProvider.getUser()?.uid ?? ''; // Obtén el ID del usuario actual
    Operador? operador = await _operadorProvider.getById(userId);
    return operador;
  }
}
