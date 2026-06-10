import 'app_reload_stub.dart'
    if (dart.library.html) 'app_reload_web.dart';

/// Reloads the app — page reload on web, no-op on native.
void reloadApp() => platformReload();
