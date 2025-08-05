import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpiPaymentPage extends StatefulWidget {
  @override
  _UpiPaymentPageState createState() => _UpiPaymentPageState();
}

class _UpiPaymentPageState extends State<UpiPaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // UPI payment details
  final String upiId = "7028682235@axl";
  final String receiverName = "Kalpesh";

  Future<void> _initiateUpiPayment(String appPackage, String appName) async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final note =
        _noteController.text.isEmpty ? "Payment" : _noteController.text;

    if (amount <= 0) {
      _showSnackBar("Please enter a valid amount");
      return;
    }

    try {
      // Create UPI URL with proper formatting
      final transactionRef = "TXN${DateTime.now().millisecondsSinceEpoch}";
      final upiUrl = "upi://pay"
          "?pa=$upiId"
          "&pn=${Uri.encodeComponent(receiverName)}"
          "&am=$amount"
          "&tn=${Uri.encodeComponent(note)}"
          "&cu=INR"
          "&tr=$transactionRef"
          "&mode=02"
          "&purpose=00";

      if (await canLaunchUrl(Uri.parse(upiUrl))) {
        await launchUrl(Uri.parse(upiUrl),
            mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("Could not launch $appName");
      }
    } catch (e) {
      _showSnackBar("Error initiating payment: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("UPI Payment"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Details",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    Text("Receiver: $receiverName"),
                    Text("UPI ID: $upiId"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount",
                prefixText: "₹ ",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: "Note (Optional)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Select UPI App",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildUpiAppCard(
                    "Google Pay",
                    "com.google.android.apps.nbu.paisa.user",
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                  _buildUpiAppCard(
                    "PhonePe",
                    "com.phonepe.app",
                    Icons.phone_android,
                    Colors.purple,
                  ),
                  _buildUpiAppCard(
                    "Paytm",
                    "net.one97.paytm",
                    Icons.payment,
                    Colors.blue.shade900,
                  ),
                  _buildUpiAppCard(
                    "BHIM",
                    "in.org.npci.upiapp",
                    Icons.account_balance,
                    Colors.orange,
                  ),
                  _buildUpiAppCard(
                    "Amazon Pay",
                    "in.amazon.mShop.android.shopping",
                    Icons.shopping_cart,
                    Colors.orange.shade800,
                  ),
                  _buildUpiAppCard(
                    "WhatsApp",
                    "com.whatsapp",
                    Icons.chat,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiAppCard(
      String name, String package, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _initiateUpiPayment(package, name),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
