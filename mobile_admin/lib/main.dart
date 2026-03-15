import 'package:flutter/widgets.dart';

import 'app/admin_app.dart';
import 'core/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.ensureInitialized();
  runApp(const AdminApp());
}
