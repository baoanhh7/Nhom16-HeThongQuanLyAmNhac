import 'package:flutter/material.dart';
import 'package:flutter_music_app/screens/home_screen.dart';
import 'package:flutter_zalopay_sdk/flutter_zalopay_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import '../../config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedPlan = 0;
  int? userId;
  final List<Map<String, dynamic>> _plans = [
    {
      'name': '1 tháng',
      'price': 59000,
      'description': 'Gói cơ bản',
      'color': Colors.blue,
      'popular': false,
      'day': 30,
    },
    {
      'name': '3 tháng',
      'price': 159000,
      'description': 'Tiết kiệm 10%',
      'color': Colors.orange,
      'popular': true,
      'day': 90,
    },
    {
      'name': '12 tháng',
      'price': 499000,
      'description': 'Tiết kiệm 30%',
      'color': Colors.green,
      'popular': false,
      'day': 365,
    },
  ];
  Future<int?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || JwtDecoder.isExpired(token)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    // Dựa theo cách bạn tạo token bằng ClaimTypes.NameIdentifier:
    // => nó sẽ lưu trong key "nameid"
    final userId = decodedToken['nameid']; // hoặc 'sub' nếu bạn đổi claim

    return int.tryParse(userId.toString());
  }

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    userId = await getUserIdFromToken();
    setState(() {}); // nếu cần cập nhật UI
  }

  Future<void> _handleZaloPayPayment() async {
    final plan = _plans[_selectedPlan];

    try {
      // Gọi API backend để lấy zp_trans_token
      final response = await http.post(
        Uri.parse('${ip}ZaloPay/payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"amount": plan['price']}),
      );

      if (response.statusCode != 200) {
        throw Exception("Lỗi server: ${response.statusCode}");
      }

      final data = json.decode(response.body);
      final zpToken = data['zp_trans_token'];

      if (zpToken == null) {
        throw Exception("Không nhận được zpToken từ server.");
      }

      final result = await FlutterZaloPaySdk.payOrder(zpToken: zpToken);

      String message;
      switch (result) {
        case FlutterZaloPayStatus.success:
          message = "Thanh toán thành công!";
          if (!mounted) return;
          final confirmResponse = await http.post(
            Uri.parse('${ip}ZaloPay/confirm'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "userId": userId,
              "amount": plan['price'],
              "durationDays": plan['day'],
            }),
          );

          // In kết quả để debug
          debugPrint("Confirm API status: ${confirmResponse.statusCode}");
          debugPrint("Confirm API body: ${confirmResponse.body}");

          if (confirmResponse.statusCode == 200) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Xác nhận thanh toán thất bại: ${confirmResponse.body}",
                ),
              ),
            );
          }
          break;

        case FlutterZaloPayStatus.cancelled:
          message = "Bạn đã huỷ thanh toán.";
          Navigator.pop(context);
          break;

        case FlutterZaloPayStatus.failed:
        default:
          message = "Thanh toán thất bại!";
          Navigator.pop(context);
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi gọi thanh toán: $e")));
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          "Chọn gói Premium",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1117), Color(0xFF161B22)],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.stars,
                      size: 48,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Nâng cấp lên Premium",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Trải nghiệm âm nhạc không giới hạn",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Plans Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final isSelected = _selectedPlan == index;
                    final isPopular = plan['popular'] as bool;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Stack(
                        children: [
                          // Main Card
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? plan['color'].withOpacity(0.1)
                                      : const Color(0xFF21262D),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? plan['color']
                                        : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: plan['color'].withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                      : [],
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPlan = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    // Plan Icon
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: plan['color'].withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        Icons.music_note,
                                        color: plan['color'],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Plan Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            plan['description'],
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                "${_formatPrice(plan['price'])} VNĐ",
                                                style: TextStyle(
                                                  color: plan['color'],
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (index > 0)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "Tiết kiệm",
                                                    style: TextStyle(
                                                      color: Colors.green[400],
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Selection Radio
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? plan['color']
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? plan['color']
                                                  : Colors.grey[600]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check : null,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Popular Badge
                          if (isPopular)
                            Positioned(
                              top: -5,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "PHỔ BIẾN",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Payment Button
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Features List
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21262D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Tính năng Premium",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFeature(Icons.music_off, "Không quảng cáo"),
                            _buildFeature(Icons.download, "Tải offline"),
                            _buildFeature(
                              Icons.skip_next,
                              "Bỏ qua không giới hạn",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _plans[_selectedPlan]['color'],
                          _plans[_selectedPlan]['color'].withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: _plans[_selectedPlan]['color'].withOpacity(
                            0.3,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _handleZaloPayPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Thanh toán với ZaloPay",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "Tự động gia hạn • Hủy bất kỳ lúc nào",
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[400], size: 24),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[300], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
