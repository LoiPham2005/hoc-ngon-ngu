package com.loipham.lingua

import android.view.LayoutInflater
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
// google_mobile_ads 9.0.0: NativeAdFactory là top-level interface.
import io.flutter.plugins.googlemobileads.NativeAdFactory

/**
 * Native ad factory FULL-SCREEN — MediaView fill toàn bộ space còn lại,
 * text + CTA dồn xuống đáy. Render khi
 * `NativeAd(factoryId: 'nativeFull', ...)` được gọi từ Dart.
 *
 * Layout: `res/layout/native_ad_full.xml`
 */
class NativeAdFactoryFull(
    private val layoutInflater: LayoutInflater
) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val view = layoutInflater.inflate(R.layout.native_ad_full, null) as NativeAdView

        val headline = view.findViewById<TextView>(R.id.ad_headline)
        val body = view.findViewById<TextView>(R.id.ad_body)
        val cta = view.findViewById<Button>(R.id.ad_call_to_action)
        val icon = view.findViewById<ImageView>(R.id.ad_icon)
        val advertiser = view.findViewById<TextView>(R.id.ad_advertiser)
        val media = view.findViewById<MediaView>(R.id.ad_media)

        headline.text = nativeAd.headline
        view.headlineView = headline

        nativeAd.body?.let {
            body.text = it
            body.visibility = android.view.View.VISIBLE
        } ?: run { body.visibility = android.view.View.GONE }
        view.bodyView = body

        nativeAd.callToAction?.let {
            cta.text = it
            cta.visibility = android.view.View.VISIBLE
        } ?: run { cta.visibility = android.view.View.GONE }
        view.callToActionView = cta

        nativeAd.icon?.let {
            icon.setImageDrawable(it.drawable)
            icon.visibility = android.view.View.VISIBLE
        } ?: run { icon.visibility = android.view.View.GONE }
        view.iconView = icon

        nativeAd.advertiser?.let {
            advertiser.text = it
            advertiser.visibility = android.view.View.VISIBLE
        } ?: run { advertiser.visibility = android.view.View.GONE }
        view.advertiserView = advertiser

        view.mediaView = media

        view.setNativeAd(nativeAd)
        return view
    }
}
