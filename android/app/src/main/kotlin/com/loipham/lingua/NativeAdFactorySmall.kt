package com.loipham.lingua

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
// google_mobile_ads 9.0.0: NativeAdFactory là top-level interface
// (trước v9 nằm nested trong GoogleMobileAdsPlugin).
import io.flutter.plugins.googlemobileads.NativeAdFactory

/**
 * Native ad factory SMALL (~80dp height) — banner-like.
 * Dùng khi `NativeAd(factoryId: 'nativeSmall', ...)` từ Dart.
 *
 * Layout: `res/layout/native_ad_small.xml`
 */
class NativeAdFactorySmall(
    private val layoutInflater: LayoutInflater
) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val view = layoutInflater.inflate(R.layout.native_ad_small, null) as NativeAdView

        val headline = view.findViewById<TextView>(R.id.ad_headline)
        val body = view.findViewById<TextView>(R.id.ad_body)
        val cta = view.findViewById<Button>(R.id.ad_call_to_action)
        val icon = view.findViewById<ImageView>(R.id.ad_icon)

        headline.text = nativeAd.headline
        view.headlineView = headline

        nativeAd.body?.let {
            body.text = it
            body.visibility = View.VISIBLE
        } ?: run { body.visibility = View.GONE }
        view.bodyView = body

        nativeAd.callToAction?.let {
            cta.text = it
            cta.visibility = View.VISIBLE
        } ?: run { cta.visibility = View.GONE }
        view.callToActionView = cta

        nativeAd.icon?.let {
            icon.setImageDrawable(it.drawable)
            icon.visibility = View.VISIBLE
        } ?: run { icon.visibility = View.GONE }
        view.iconView = icon

        view.setNativeAd(nativeAd)
        return view
    }
}
