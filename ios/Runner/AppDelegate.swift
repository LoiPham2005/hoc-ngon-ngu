import Flutter
import UIKit
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // ⚡ Register native ad factories — `factoryId` phải match Dart:
    //    NativeAd(factoryId: 'nativeSmall' / 'nativeMedium' / 'nativeFull')
    let smallFactory = NativeAdFactorySmall()
    let mediumFactory = NativeAdFactoryMedium()
    let fullFactory = NativeAdFactoryFull()

    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "nativeSmall",
      nativeAdFactory: smallFactory
    )
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "nativeMedium",
      nativeAdFactory: mediumFactory
    )
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "nativeFull",
      nativeAdFactory: fullFactory
    )
  }
}
