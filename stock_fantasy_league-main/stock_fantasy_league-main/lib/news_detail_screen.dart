import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final String title;
  final String url;
  final String imageUrl;

  const NewsDetailScreen({
    super.key, 
    required this.title, 
    required this.url, 
    required this.imageUrl
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  String? aiSummary;
  bool isLoading = false; 

  Future<void> _generateSummary() async {
    setState(() => isLoading = true);
    
    String result = await AIService.getSummary(widget.title);

    if (mounted) {
      setState(() {
        aiSummary = result;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(widget.imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            
            // Τίτλος
            Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            const Align(
              alignment: Alignment.centerLeft, 
              child: Text("AI SUMMARY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))
            ),
            const Divider(),
            
            const SizedBox(height: 10),

            if (aiSummary == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _generateSummary,
                  icon: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                  label: Text(isLoading ? "GENERATING..." : "SUMMARIZE WITH AI"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!)
                ),
                child: Text(
                  aiSummary!, 
                  style: const TextStyle(fontSize: 16, height: 1.5, fontStyle: FontStyle.italic)
                ),
              ),
            
            const SizedBox(height: 40),
            
            OutlinedButton(
              onPressed: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("VIEW FULL STORY ON WEB"),
            )
          ],
        ),
      ),
    );
  }
}