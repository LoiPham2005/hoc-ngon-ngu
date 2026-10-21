package com.loipham.lingua

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

// FlutterFragmentActivity: local_auth (vân tay/Face ID) cần FragmentActivity.
class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ⚡ Register native ad factories — `factoryId` phải match Dart:
        //    NativeAd(factoryId: 'nativeSmall' / 'nativeMedium' / 'nativeFull')
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "nativeSmall",
            NativeAdFactorySmall(layoutInflater)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "nativeMedium",
            NativeAdFactoryMedium(layoutInflater)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "nativeFull",
            NativeAdFactoryFull(layoutInflater)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "nativeSmall")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "nativeMedium")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "nativeFull")
    }
}
