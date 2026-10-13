import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'result_screen.dart';

const baseUrl = 'http://127.0.0.1:8000';

void main() {
  runApp(const PatentabilityApp());
}

class PatentabilityApp extends StatelessWidget {
  const PatentabilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Patentability Prediction',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Arial'),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? fileName;
  Uint8List? fileBytes;
  bool loading = false;
  String? error;

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;

    setState(() {
      fileName = result.files.single.name;
      fileBytes = result.files.single.bytes;
      error = null;
    });
  }

  Future<void> analyze() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'));
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes!, filename: fileName),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (!mounted) return;
      setState(() => loading = false);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(data: data)),
        );
      } else {
        setState(() => error = data['detail'].toString());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not connect to server';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F0FA),
        title: const Text('Patentability Prediction'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Welcome to Patentability Prediction',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload your patent document to predict its patentability.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              Container(
                width: 330,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7654D9)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 70,
                      color: Color(0xFF6846C6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fileName ?? 'Upload PDF',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: loading ? null : pickPdf,
                      child: const Text('Choose PDF'),
                    ),
                    if (fileBytes != null) ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: loading ? null : analyze,
                        child: Text(loading ? 'Analyzing...' : 'Analyze'),
                      ),
                    ],
                  ],
                ),
              ),
              if (loading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
              if (error != null) ...[
                const SizedBox(height: 20),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}