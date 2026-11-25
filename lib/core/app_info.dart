import 'package:flutter/services.dart' show appFlavor;

/// Whether this is Zenith Debug, the flavor installed alongside Zenith.
const isDebugFlavor = appFlavor == 'dev';

const appName = isDebugFlavor ? 'Zenith Debug' : 'Zenith';
