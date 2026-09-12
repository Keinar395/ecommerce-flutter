import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Payment3DScreen extends StatefulWidget {
  // C# API'mizden gelen HTML string'i buraya alacağız
  final String htmlContent;

  const Payment3DScreen({super.key, required this.htmlContent});

  @override
  State<Payment3DScreen> createState() => _Payment3DScreenState();
}

class _Payment3DScreenState extends State<Payment3DScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // WebView Ayarlarını ve Navigasyon Dinleyicisini Kuruyoruz
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Sihir Burada: Sayfa daha yüklenmeye çalışırken araya giriyoruz!
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('payment/callback')) {
              // Callback adresini gördüğümüz an sayfanın yüklenmesini iptal edip başarıyla geri dönüyoruz
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Güvenli Ödeme (3D Secure)',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        // Kullanıcı çarpıya basıp çıkarsa ödeme iptal sayılır (false döndürüyoruz)
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.black)),
        ],
      ),
    );
  }
}
