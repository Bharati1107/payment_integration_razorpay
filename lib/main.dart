import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Razorpay UPI Payment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RazorpayPaymentPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RazorpayPaymentPage extends StatefulWidget {
  @override
  _RazorpayPaymentPageState createState() => _RazorpayPaymentPageState();
}

class _RazorpayPaymentPageState extends State<RazorpayPaymentPage> {
  static const String _razorpayKey =
      'rzp_test_cF9FGU2a6ZSD2f'; // Replace with your key

  late Razorpay _razorpay;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  String _paymentStatus = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Set default test values
    _nameController.text = "Test User";
    _emailController.text = "test@example.com";
    _phoneController.text = "1234567890";
    _amountController.text = "100";
    _descriptionController.text = "Test Payment";
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      _isLoading = false;
      _paymentStatus = 'SUCCESS';
    });

    _showPaymentDialog(
      'Payment Successful!',
      'Payment ID: ${response.paymentId}\nOrder ID: ${response.orderId}\nSignature: ${response.signature}',
      Colors.green,
      Icons.check_circle,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isLoading = false;
      _paymentStatus = 'FAILED';
    });

    // Handle specific error cases
    String errorMessage = 'Payment failed';
    if (response.message != null) {
      errorMessage = response.message!;
    }

    _showPaymentDialog(
      'Payment Failed!',
      'Error: $errorMessage\nCode: ${response.code ?? 'Unknown'}',
      Colors.red,
      Icons.error,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isLoading = false;
      _paymentStatus = 'EXTERNAL_WALLET';
    });

    _showPaymentDialog(
      'External Wallet',
      'Wallet: ${response.walletName ?? 'Unknown'}',
      Colors.orange,
      Icons.account_balance_wallet,
    );
  }

  void _showPaymentDialog(
      String title, String content, Color color, IconData icon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _startPayment() {
    // Validate inputs
    if (_amountController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount');
      return;
    }

    // Email validation
    if (!_emailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email');
      return;
    }

    // Phone validation
    if (_phoneController.text.length != 10) {
      _showSnackBar('Please enter a valid 10-digit phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _paymentStatus = '';
    });

    var options = {
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'UPI Payment App',
      'description': _descriptionController.text.isEmpty
          ? 'Payment'
          : _descriptionController.text,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': _phoneController.text,
        'email': _emailController.text,
        'name': _nameController.text,
      },
      'external': {
        'wallets': ['paytm'] // Enable external wallets
      },
      'method': {
        'upi': true,
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
      'theme': {'color': '#2196F3'}
    };

    try {
      _razorpay.open(options);

      // Set a timeout to reset loading state if no response
      Timer(Duration(minutes: 2), () {
        if (_isLoading) {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Payment timeout. Please try again.');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error initializing payment: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Razorpay UPI Payment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            if (_paymentStatus.isNotEmpty)
              Card(
                color: _paymentStatus == 'SUCCESS'
                    ? Colors.green.shade50
                    : _paymentStatus == 'FAILED'
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _paymentStatus == 'SUCCESS'
                            ? Icons.check_circle
                            : _paymentStatus == 'FAILED'
                                ? Icons.error
                                : Icons.account_balance_wallet,
                        color: _paymentStatus == 'SUCCESS'
                            ? Colors.green
                            : _paymentStatus == 'FAILED'
                                ? Colors.red
                                : Colors.orange,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Payment Status: $_paymentStatus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _paymentStatus == 'SUCCESS'
                              ? Colors.green.shade700
                              : _paymentStatus == 'FAILED'
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Customer Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Details',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        prefixText: '+91 ',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Payment Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                        prefixText: '₹ ',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Enter payment description',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Text(
                        'Pay with Razorpay',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            SizedBox(height: 24),

            // Features Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ Razorpay Features',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                        '• Multiple payment methods (UPI, Cards, Net Banking)'),
                    Text('• Secure payment processing'),
                    Text('• Real-time payment status'),
                    Text('• Automatic payment confirmations'),
                    Text('• Support for all major UPI apps'),
                    Text('• Better success rates than direct UPI'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Setup Instructions Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚙️ Setup Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Add to pubspec.yaml:'),
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'dependencies:\n  razorpay_flutter: ^1.3.7',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    Text('2. Get Razorpay account at razorpay.com'),
                    Text('3. Replace API key with your test/live key'),
                    Text('4. Add internet permission in AndroidManifest.xml'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
