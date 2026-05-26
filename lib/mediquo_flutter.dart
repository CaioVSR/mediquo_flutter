/// MediQuo telemedicine integration for Flutter.
///
/// This package is a federated plugin that bridges the native MediQuo Android
/// and iOS SDKs (chat, video calls and the professional list).
///
/// The public API is plain Dart: create a `Mediquo` and call its
/// `Future`-returning methods. The package holds no observable state and
/// imposes no state-management library: drive it from `setState`,
/// `ChangeNotifier`, Riverpod, Bloc or anything else. Failures are thrown as
/// `MediquoException`s.
///
/// ```dart
/// final mediquo = Mediquo();
/// await mediquo.startSession(
///   MediquoConfiguration.validated(apiKey: apiKey, clientCode: clientCode),
/// );
/// await mediquo.openProfessionalList();
/// ```
library;

export 'src/exceptions/mediquo_error_code.dart';
export 'src/exceptions/mediquo_exception.dart';
export 'src/mediquo.dart';
export 'src/models/mediquo_configuration.dart';
export 'src/models/mediquo_push_token.dart';
export 'src/platform/mediquo_flutter_platform.dart';
