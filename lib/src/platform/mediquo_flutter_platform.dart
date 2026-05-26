import 'package:mediquo_flutter/src/models/mediquo_push_token.dart';
import 'package:mediquo_flutter/src/platform/mediquo_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface every platform implementation of the MediQuo plugin must
/// satisfy.
///
/// Platform implementations should extend this class rather than implement it,
/// so that new methods added here do not silently break existing
/// implementations. The default implementation,
/// [MediquoFlutterMethodChannel], talks to the native SDKs over a Pigeon
/// channel.
///
/// Tests and alternative platform implementations swap [instance] for a fake.
abstract class MediquoFlutterPlatform extends PlatformInterface {
  /// Constructs a [MediquoFlutterPlatform].
  MediquoFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediquoFlutterPlatform _instance = MediquoFlutterMethodChannel();

  /// The active platform implementation.
  static MediquoFlutterPlatform get instance => _instance;

  /// Replaces the active platform implementation.
  ///
  /// The provided [instance] is verified against the platform-interface token
  /// to guard against implementations that do not extend
  /// [MediquoFlutterPlatform].
  static set instance(MediquoFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialises the native SDK with the partner [apiKey].
  Future<void> initialize(String apiKey) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Authenticates the pre-registered patient identified by [clientCode].
  Future<void> authenticate(String clientCode) {
    throw UnimplementedError('authenticate() has not been implemented.');
  }

  /// Presents the native professional-list interface.
  Future<void> openProfessionalList() {
    throw UnimplementedError(
      'openProfessionalList() has not been implemented.',
    );
  }

  /// Logs the current patient out of the native SDK.
  Future<void> deauthenticate() {
    throw UnimplementedError('deauthenticate() has not been implemented.');
  }

  /// Registers a push [token] with the native SDK.
  Future<void> registerPushToken(MediquoPushToken token) {
    throw UnimplementedError('registerPushToken() has not been implemented.');
  }

  /// Presents the SDK screen for a tapped remote notification described by
  /// [payload].
  Future<void> openFromRemoteNotification(Map<String, Object?> payload) {
    throw UnimplementedError(
      'openFromRemoteNotification() has not been implemented.',
    );
  }
}
