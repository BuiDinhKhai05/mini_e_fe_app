// lib/screens/orders_payments/payment_qr_screen.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';

class PaymentQrScreen extends StatefulWidget {
  static const routeName = '/payment-gateway';

  // Giữ nguyên tên field cũ để không phải sửa main.dart.
  // qrData hiện được hiểu là paymentUrl VNPAY do backend trả về.
  final String qrData;
  final double amount;
  final String sessionCode;
  final String orderIdToCheck;

  const PaymentQrScreen({
    Key? key,
    required this.qrData,
    required this.amount,
    required this.sessionCode,
    required this.orderIdToCheck,
  }) : super(key: key);

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _pageBg = AppColors.background;
  static const Color _textDark = AppColors.textDark;
  static const Color _textMuted = AppColors.textGrey;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
  );

  WebViewController? _webViewController;

  Timer? _countdownTimer;
  Timer? _pollingTimer;

  int _timeLeft = 900;
  int _progress = 0;

  bool _isChecking = false;
  bool _isFinishing = false;
  bool _hasSeenReturnUrl = false;
  bool _openedWebPayment = false;

  String get _paymentUrl => widget.qrData.trim();

  @override
  void initState() {
    super.initState();

    // Android/iOS: dùng WebView.
    // Chrome/Web: tuyệt đối không init WebViewController vì sẽ lỗi WebViewPlatform.instance.
    if (!kIsWeb && _paymentUrl.isNotEmpty) {
      _initMobileWebView();
    }

    _startCountdown();
    _startPolling();

    // Chrome/Web: mở VNPAY bằng tab mới để dev được.
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPaymentInBrowser();
      });
    }
  }

  void _initMobileWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
          onPageStarted: (url) {
            _handleUrlChanged(url, fromPageFinished: false);
          },
          onPageFinished: (url) {
            _handleUrlChanged(url, fromPageFinished: true);
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;

            _handleUrlChanged(url, fromPageFinished: false);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            if (_isAppDeepLink(url)) {
              _hasSeenReturnUrl = true;
              _checkPaymentStatus(forceFinish: true);
              return NavigationDecision.prevent;
            }

            if (_isPaymentResultUrl(url)) {
              _hasSeenReturnUrl = true;
              _checkPaymentStatus(forceFinish: true);
              return NavigationDecision.prevent;
            }

            // Return URL của BE: cho WebView chạy tiếp để BE xử lý callback/redirect.
            if (_isVnpayReturnUrl(url)) {
              _hasSeenReturnUrl = true;
              return NavigationDecision.navigate;
            }

            // Các link dạng app ngân hàng, intent://, banking://...
            // thì mở bằng app ngoài.
            if (!_isHttpUrl(url)) {
              _openExternalUrl(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (kDebugMode) {
              debugPrint('[VNPAY WEBVIEW ERROR] ${error.description}');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_paymentUrl));
  }

  bool _isHttpUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool _isAppDeepLink(String url) {
    return url.startsWith('mochi://') ||
        url.startsWith('minie://') ||
        url.startsWith('mini-ecommerce://');
  }

  bool _isVnpayReturnUrl(String url) {
    final lowerUrl = url.toLowerCase();

    return lowerUrl.contains('/payments/vnpay/return') ||
        lowerUrl.contains('/api/payments/vnpay/return') ||
        lowerUrl.contains('/vnpay/return') ||
        lowerUrl.contains('vnp_responsecode=');
  }

  bool _isPaymentResultUrl(String url) {
    final lowerUrl = url.toLowerCase();

    return lowerUrl.contains('/payment-result') ||
        lowerUrl.contains('/payments/result') ||
        lowerUrl.contains('status=success') ||
        lowerUrl.contains('status=paid') ||
        lowerUrl.contains('status=failed');
  }

  void _handleUrlChanged(String url, {required bool fromPageFinished}) {
    if (_isFinishing) return;

    if (_isAppDeepLink(url) || _isPaymentResultUrl(url)) {
      _hasSeenReturnUrl = true;
      _checkPaymentStatus(forceFinish: true);
      return;
    }

    if (_isVnpayReturnUrl(url)) {
      _hasSeenReturnUrl = true;

      // Chờ BE xử lý xong return URL rồi mới kiểm tra đơn.
      if (fromPageFinished) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted || _isFinishing) return;
          _checkPaymentStatus(forceFinish: true);
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinishing) return;

      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
        return;
      }

      _navigateToResult(
        false,
        message: 'Hết thời gian thanh toán. Vui lòng tạo lại giao dịch.',
      );
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus({bool forceFinish = false}) async {
    if (_isChecking || _isFinishing) return;

    _isChecking = true;

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      final isPaid = await orderProvider.checkPaidBySessionCode(
        widget.sessionCode,
      );

      if (!mounted || _isFinishing) return;

      if (isPaid) {
        await orderProvider.fetchMyOrders(refresh: true);

        if (!mounted || _isFinishing) return;

        _navigateToResult(
          true,
          message: 'Thanh toán VNPAY thành công. Đơn hàng đã được tạo.',
        );
        return;
      }

      if (forceFinish && _hasSeenReturnUrl) {
        _navigateToResult(
          false,
          message:
          'Chưa xác nhận được thanh toán. Nếu bạn đã bị trừ tiền, hãy kiểm tra lại trong mục đơn hàng sau vài giây.',
        );
      }
    } catch (_) {
      if (forceFinish && mounted && !_isFinishing) {
        _navigateToResult(
          false,
          message: 'Không kiểm tra được trạng thái thanh toán.',
        );
      }
    } finally {
      _isChecking = false;
    }
  }

  void _navigateToResult(bool success, {String? message}) {
    if (_isFinishing || !mounted) return;

    _isFinishing = true;

    _countdownTimer?.cancel();
    _pollingTimer?.cancel();

    Navigator.pushReplacementNamed(
      context,
      '/payment-result',
      arguments: {
        'success': success,
        'message': message ??
            (success ? 'Thanh toán thành công!' : 'Thanh toán thất bại'),
        'orderId': widget.sessionCode,
      },
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showSnack('Link thanh toán không hợp lệ');
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack('Không thể mở ứng dụng thanh toán ngoài');
    }
  }

  Future<void> _openPaymentInBrowser() async {
    if (_openedWebPayment || _paymentUrl.isEmpty) return;

    _openedWebPayment = true;

    final uri = Uri.tryParse(_paymentUrl);

    if (uri == null) {
      _showSnack('Link thanh toán VNPAY không hợp lệ');
      return;
    }

    try {
      // Khi chạy Chrome/Web: mở tab mới.
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      _showSnack('Không thể mở trang thanh toán VNPAY');
    }
  }

  Future<bool> _handleBackPressed() async {
    if (!kIsWeb && _webViewController != null) {
      final canGoBack = await _webViewController!.canGoBack();

      if (canGoBack) {
        await _webViewController!.goBack();
        return false;
      }
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thoát thanh toán?'),
          content: const Text(
            'Giao dịch VNPAY có thể chưa hoàn tất. Bạn vẫn muốn thoát?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ở lại'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thoát'),
            ),
          ],
        );
      },
    );

    return shouldExit == true;
  }

  String get _timerString {
    final minutes = (_timeLeft / 60).floor().toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentUrl.isEmpty) {
      return Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          title: const Text('Thanh toán VNPAY'),
          backgroundColor: Colors.white,
          foregroundColor: _textDark,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Không có link thanh toán VNPAY'),
        ),
      );
    }

    if (kIsWeb) {
      return _buildWebFallbackScreen();
    }

    return _buildMobileWebViewScreen();
  }

  Widget _buildMobileWebViewScreen() {
    final controller = _webViewController;

    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          title: const Column(
            children: [
              Text(
                'Thanh toán VNPAY',
                style: TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Thanh toán trực tiếp trong ứng dụng',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: _textDark,
          actions: [
            IconButton(
              tooltip: 'Tải lại',
              onPressed: () => controller?.reload(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildPaymentInfoBar(),
              if (_progress < 100) _buildProgressBar(),
              Expanded(
                child: controller == null
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: _primaryPink,
                  ),
                )
                    : WebViewWidget(controller: controller),
              ),
              _buildBottomStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebFallbackScreen() {
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          title: const Column(
            children: [
              Text(
                'Thanh toán VNPAY',
                style: TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Chế độ dev bằng Chrome',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: _textDark,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              children: [
                _buildWebPaymentCard(),
                const SizedBox(height: 18),
                _buildTimerChip(),
                const SizedBox(height: 18),
                _buildWaitingBox(),
                const SizedBox(height: 14),
                _buildWebActionButtons(),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _navigateToResult(
                      true,
                      message: '(DEV) Giả lập thanh toán thành công',
                    ),
                    child: const Text(
                      '(DEV ONLY) Giả lập: Đã thanh toán',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _primaryPink.withOpacity(0.10)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: _softPink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: _primaryPink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currencyFormat.format(widget.amount),
                  style: const TextStyle(
                    color: _primaryPink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mã giao dịch: ${widget.sessionCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _buildSmallTimerChip(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: _progress <= 0 ? null : _progress / 100,
      minHeight: 3,
      backgroundColor: _softPink,
      color: _primaryPink,
    );
  }

  Widget _buildWebPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: _primaryPink.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _softPink,
              borderRadius: BorderRadius.circular(AppRadius.circle),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.web_rounded, color: _primaryPink, size: 16),
                SizedBox(width: 6),
                Text(
                  'Dev bằng Chrome',
                  style: TextStyle(
                    color: _primaryPink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'VNPAY',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Flutter Web không hỗ trợ nhúng WebView. Khi chạy Chrome, app sẽ mở trang VNPAY ở tab mới. Khi chạy Android/iOS, app sẽ nhúng VNPAY bằng WebView.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textMuted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _currencyFormat.format(widget.amount),
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: _primaryPink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mã giao dịch: ${widget.sessionCode}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _softPink,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: SelectableText(
              _paymentUrl,
              style: const TextStyle(fontSize: 12, color: _textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openPaymentInBrowser,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Mở lại trang thanh toán VNPAY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _checkPaymentStatus(forceFinish: false),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tôi đã thanh toán - kiểm tra trạng thái'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryPink,
              side: BorderSide(color: _primaryPink.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(color: AppColors.warning.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Text(
            'Hết hạn sau: $_timerString',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.warning,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTimerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            color: AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            _timerString,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: _primaryPink.withOpacity(0.10)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _primaryPink,
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'Đang chờ xác nhận thanh toán...',
              style: TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _primaryPink.withOpacity(0.10)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _primaryPink,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Đang chờ VNPAY xác nhận thanh toán...',
              style: TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _checkPaymentStatus(forceFinish: false),
            child: const Text(
              'Kiểm tra',
              style: TextStyle(
                color: _primaryPink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }
}