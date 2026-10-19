import 'package:injectable/injectable.dart';

import 'di.dart';
import 'injectable.config.dart';

// Init only. Features import `di.dart` for getIt / annotations — not this file.
@InjectableInit(ignoreUnregisteredTypes: [])
void configureDependencies() => getIt.init();
