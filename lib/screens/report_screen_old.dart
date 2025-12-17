import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/views/gradient_container.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildInfoItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    const email = 'water@tapps.app';
    const subject = 'Water Issue Report';
    final body = '''
Location: ${_locationController.text}

Issue Description:
${_descriptionController.text}

Contact Information:
${_phoneController.text}

Submitted from Tapps App
'''.trim();

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      // Try to launch the email client
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );

      if (!context.mounted) return;

      if (launched) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening email client...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Clear form
        _locationController.clear();
        _descriptionController.clear();
        _phoneController.clear();
      } else {
        // If no email app found, show manual email instructions
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Email Client Not Found'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please send an email with the following details:'),
                const SizedBox(height: 16),
                const Text('To: $email', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Subject: $subject', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Body:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(body),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Copy email details to clipboard
                  Clipboard.setData(ClipboardData(
                    text: 'To: $email\nSubject: $subject\n\n$body',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email details copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Copy to Clipboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      
      // Show error message with copy to clipboard option
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error Sending Email'),
          content: Text('An error occurred: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                // Copy email details to clipboard
                Clipboard.setData(ClipboardData(
                  text: 'To: $email\nSubject: $subject\n\n$body',
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email details copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Copy to Clipboard'),
            ),
          ],
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Water Issue'),
        elevation: 0,
      ),
      body: GradientContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Information Card
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What to Report?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoItem('🚰', 'Water Leaks', 'Report any visible water leaks in public areas'),
                        _buildInfoItem('💧', 'Pipe Bursts', 'Report burst pipes or major water main breaks'),
                        _buildInfoItem('⚠️', 'Water Quality', 'Report discolored, smelly, or contaminated water'),
                        _buildInfoItem('🚱', 'No Water Supply', 'Report complete loss of water supply'),
                        _buildInfoItem('🌊', 'Water Wastage', 'Report cases of water wastage or misuse'),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Water Saving Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTipItem('💧 Fix leaks promptly'),
                        _buildTipItem('🚿 Take shorter showers'),
                        _buildTipItem('🚰 Turn off tap while brushing'),
                        _buildTipItem('🌱 Water plants in the early morning or evening'),
                        _buildTipItem('🧺 Run full loads in washing machines'),
                      ],
                    ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Details',
                            style: TextStyles.h2.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Enter location',
                              hintStyle: const TextStyle(color: Colors.black45),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Issue Description',
                            style: TextStyles.h2.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Describe the water issue...',
                              hintStyle: const TextStyle(color: Colors.black45),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Contact Information',
                            style: TextStyles.h2.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Your phone number',
                              hintStyle: const TextStyle(color: Colors.black45),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.phone_outlined, color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _submitReport(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Submit Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
  }
}
