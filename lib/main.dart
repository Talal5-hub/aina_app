import 'bootstrap.dart';
import 'core/config/env.dart';

Future<void> main() async {
  await bootstrap(Environment.development);
}