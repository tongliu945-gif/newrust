import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_hbb/common.dart';

class PrivacyOverlay {
  static CancelFunc? _cancelFunc;

  static void show() {
    if (_cancelFunc != null) return;
    _cancelFunc = BotToast.showWidget(
      groupKey: 'privacy_overlay',
      toastBuilder: (_) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.privacy_tip, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text(
                  translate('Privacy protection enabled, please do not touch the screen'),
                  style: TextStyle(color: Colors.white, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hide() {
    _cancelFunc?.call();
    _cancelFunc = null;
  }
}
