import Flutter
import MediQuoSDK
import UIKit

/// Flutter plugin bridging the native MediQuo iOS SDK.
///
/// Implements the Pigeon-generated `MediquoHostApi` protocol and forwards every
/// call to a `MediQuo` instance, completing each result with `.success` or a
/// `PigeonError` whose code matches `MediquoErrorCode` on the Dart side.
public class MediquoFlutterPlugin: NSObject, FlutterPlugin, MediquoHostApi {

  private enum ErrorCode {
    static let initializationFailed = "initialization_failed"
    static let authenticationFailed = "authentication_failed"
    static let openFailed = "open_failed"
    static let deauthenticationFailed = "deauthentication_failed"
    static let pushRegistrationFailed = "push_registration_failed"
    static let notInitialized = "not_initialized"
  }

  private var apiKey: String?
  private var mediquo: MediQuo?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = MediquoFlutterPlugin()
    MediquoHostApiSetup.setUp(
      binaryMessenger: registrar.messenger(),
      api: plugin
    )
  }

  func initialize(
    apiKey: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    self.apiKey = apiKey
    completion(.success(()))
  }

  func authenticate(
    clientCode: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let apiKey else {
      completion(
        .failure(
          PigeonError(
            code: ErrorCode.notInitialized,
            message: "Initialise the SDK before authenticating.",
            details: nil
          )
        )
      )
      return
    }
    Task {
      do {
        mediquo = try await MediQuo(apiKey: apiKey, userID: clientCode)
        completion(.success(()))
      } catch {
        completion(
          .failure(
            PigeonError(
              code: ErrorCode.authenticationFailed,
              message: error.localizedDescription,
              details: nil
            )
          )
        )
      }
    }
  }

  func openProfessionalList(
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let mediquo else {
      completion(.failure(notInitialised()))
      return
    }
    DispatchQueue.main.async {
      guard let presenter = Self.topViewController() else {
        completion(
          .failure(
            PigeonError(
              code: ErrorCode.openFailed,
              message: "No view controller available to present from.",
              details: nil
            )
          )
        )
        return
      }
      let viewController = mediquo.sdkViewController(for: .professionalList)
      presenter.present(viewController, animated: true)
      completion(.success(()))
    }
  }

  func deauthenticate(
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let mediquo else {
      completion(.failure(notInitialised()))
      return
    }
    Task {
      do {
        try await mediquo.deauthenticateSDK()
        self.mediquo = nil
        completion(.success(()))
      } catch {
        completion(
          .failure(
            PigeonError(
              code: ErrorCode.deauthenticationFailed,
              message: error.localizedDescription,
              details: nil
            )
          )
        )
      }
    }
  }

  func registerPushToken(
    token: String,
    type: PushTokenType,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let mediquo else {
      completion(.failure(notInitialised()))
      return
    }
    Task {
      do {
        switch type {
        case .fcm:
          try await mediquo.setPushNotificationToken(type: .firebase(token))
        case .apns:
          guard let data = Self.data(fromHex: token) else {
            completion(
              .failure(
                PigeonError(
                  code: ErrorCode.pushRegistrationFailed,
                  message: "The APNs token is not valid hexadecimal.",
                  details: nil
                )
              )
            )
            return
          }
          try await mediquo.setPushNotificationToken(type: .appleAPNS(data))
        }
        completion(.success(()))
      } catch {
        completion(
          .failure(
            PigeonError(
              code: ErrorCode.pushRegistrationFailed,
              message: error.localizedDescription,
              details: nil
            )
          )
        )
      }
    }
  }

  func openFromRemoteNotification(
    payload: [String: Any?],
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let mediquo else {
      completion(.failure(notInitialised()))
      return
    }
    DispatchQueue.main.async {
      guard let presenter = Self.topViewController() else {
        completion(
          .failure(
            PigeonError(
              code: ErrorCode.openFailed,
              message: "No view controller available to present from.",
              details: nil
            )
          )
        )
        return
      }
      let userInfo = payload.compactMapValues { $0 }
      let viewController = mediquo.getSDKViewController(forRemotePush: userInfo)
      presenter.present(viewController, animated: true)
      completion(.success(()))
    }
  }

  private func notInitialised() -> PigeonError {
    PigeonError(
      code: ErrorCode.notInitialized,
      message: "Authenticate a patient before this operation.",
      details: nil
    )
  }

  private static func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    let window = scene?.windows.first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }

  private static func data(fromHex hex: String) -> Data? {
    guard hex.count.isMultiple(of: 2), !hex.isEmpty else { return nil }
    var data = Data(capacity: hex.count / 2)
    var index = hex.startIndex
    while index < hex.endIndex {
      let next = hex.index(index, offsetBy: 2)
      guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
      data.append(byte)
      index = next
    }
    return data
  }
}
