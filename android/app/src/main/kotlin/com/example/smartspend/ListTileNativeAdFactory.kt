package com.example.smartspend

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class ListTileNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_list_tile, null) as NativeAdView

        with(nativeAdView) {
            // Headline
            val headlineView = findViewById<TextView>(R.id.ad_headline)
            headlineView.text = nativeAd.headline
            this.headlineView = headlineView

            // Body
            val bodyView = findViewById<TextView>(R.id.ad_body)
            if (nativeAd.body != null) {
                bodyView.text = nativeAd.body
                bodyView.visibility = View.VISIBLE
            } else {
                bodyView.visibility = View.GONE
            }
            this.bodyView = bodyView

            // Icon
            val iconView = findViewById<ImageView>(R.id.ad_icon)
            if (nativeAd.icon != null) {
                iconView.setImageDrawable(nativeAd.icon?.drawable)
                iconView.visibility = View.VISIBLE
            } else {
                iconView.visibility = View.GONE
            }
            this.iconView = iconView

            // Call to action
            val callToActionView = findViewById<TextView>(R.id.ad_call_to_action)
            if (nativeAd.callToAction != null) {
                callToActionView.text = nativeAd.callToAction
                callToActionView.visibility = View.VISIBLE
            } else {
                callToActionView.visibility = View.GONE
            }
            this.callToActionView = callToActionView

            // Advertiser
            val advertiserView = findViewById<TextView>(R.id.ad_advertiser)
            if (nativeAd.advertiser != null) {
                advertiserView.text = nativeAd.advertiser
                advertiserView.visibility = View.VISIBLE
            } else {
                advertiserView.visibility = View.GONE
            }
            this.advertiserView = advertiserView

            setNativeAd(nativeAd)
        }

        return nativeAdView
    }
}
