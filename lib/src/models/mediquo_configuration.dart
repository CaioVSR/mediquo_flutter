import 'package:meta/meta.dart';

/// Immutable credentials required to start a MediQuo session.
///
/// The plugin performs no network calls of its own. Both values are produced
/// server-side and handed to the app:
///
/// - [apiKey]: the partner API key issued by MediQuo.
/// - [clientCode]: the patient identifier (a CPF, digits only) created in
///   advance through the MediQuo Patients API.
///
/// Prefer [MediquoConfiguration.validated] to trim the inputs and fail fast on
/// obviously invalid values.
@immutable
class MediquoConfiguration {
  /// Creates a [MediquoConfiguration] from raw values without validation.
  const MediquoConfiguration({
    required this.apiKey,
    required this.clientCode,
  });

  /// Creates a [MediquoConfiguration], trimming both values and validating
  /// them.
  ///
  /// Throws an [ArgumentError] when [apiKey] is empty, or when [clientCode] is
  /// empty or contains characters other than digits.
  factory MediquoConfiguration.validated({
    required String apiKey,
    required String clientCode,
  }) {
    final normalizedApiKey = apiKey.trim();
    final normalizedClientCode = clientCode.trim();
    if (normalizedApiKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must not be empty');
    }
    if (normalizedClientCode.isEmpty) {
      throw ArgumentError.value(
        clientCode,
        'clientCode',
        'must not be empty',
      );
    }
    if (!_digitsOnly.hasMatch(normalizedClientCode)) {
      throw ArgumentError.value(
        clientCode,
        'clientCode',
        'must contain digits only (a patient CPF)',
      );
    }
    return MediquoConfiguration(
      apiKey: normalizedApiKey,
      clientCode: normalizedClientCode,
    );
  }

  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  /// The partner API key issued by MediQuo.
  final String apiKey;

  /// The patient identifier (CPF, digits only) registered server-side.
  final String clientCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediquoConfiguration &&
          runtimeType == other.runtimeType &&
          apiKey == other.apiKey &&
          clientCode == other.clientCode;

  @override
  int get hashCode => Object.hash(runtimeType, apiKey, clientCode);
}
