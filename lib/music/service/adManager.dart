// import 'dart:io';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class AdManager {
//   InterstitialAd? _interstitialAd;
//   bool _isAdReady = false;

//   void loadAd() {
//     InterstitialAd.load(
//       adUnitId:
//           Platform.isAndroid
//               ? 'ca-app-pub-3940256099942544/1033173712'
//               : 'ca-app-pub-3940256099942544/4411468910',
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (ad) {
//           _interstitialAd = ad;
//           _isAdReady = true;
//         },
//         onAdFailedToLoad: (error) {
//           _isAdReady = false;
//           _interstitialAd = null;
//         },
//       ),
//     );
//   }

//   Future<void> showAdIfNeeded(Function onAdComplete) async {
//     if (_isAdReady && _interstitialAd != null) {
//       _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
//         onAdDismissedFullScreenContent: (ad) {
//           ad.dispose();
//           _interstitialAd = null;
//           _isAdReady = false;
//           loadAd(); // load tiếp cho lần sau
//           onAdComplete(); // gọi play nhạc sau khi đóng quảng cáo
//         },
//         onAdFailedToShowFullScreenContent: (ad, error) {
//           ad.dispose();
//           _interstitialAd = null;
//           _isAdReady = false;
//           onAdComplete(); // vẫn gọi play nhạc
//         },
//       );

//       _interstitialAd!.show();
//     } else {
//       // Nếu chưa sẵn sàng thì play luôn
//       onAdComplete();
//     }
//   }
// }
