import 'package:flutter/foundation.dart';

class BrowserService extends ChangeNotifier {
  String _url = 'https://google.com';
  String get url => _url;
  bool _navigateToBrowser = false;
  bool get navigateToBrowser => _navigateToBrowser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void loadUrl(String newUrl) {
    // Ensure URL has a scheme
    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      newUrl = 'https://$newUrl';
    }
    _url = newUrl;
    _navigateToBrowser = true;
    notifyListeners();
  }

  void didNavigate() {
    _navigateToBrowser = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
