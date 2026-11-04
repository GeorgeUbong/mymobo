import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  AdSize? _bannerSize;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adUnitId = AdConfig.bannerAdUnitId;
    if (adUnitId == null || _isLoading || _bannerAd != null) return;
    _loadBannerAd(adUnitId, MediaQuery.sizeOf(context).width.truncate());
  }

  Future<void> _loadBannerAd(String adUnitId, int width) async {
    _isLoading = true;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted) return;
    if (size == null) {
      _isLoading = false;
      debugPrint('Unable to determine an adaptive banner ad size.');
      return;
    }

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _bannerSize = null;
            _isLoaded = false;
            _isLoading = false;
          });
        },
      ),
    );
    _bannerAd = bannerAd;
    _bannerSize = size;
    await bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    final bannerSize = _bannerSize;
    if (!_isLoaded || bannerAd == null || bannerSize == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: bannerSize.width.toDouble(),
      height: bannerSize.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}
