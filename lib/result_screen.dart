import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultScreen({super.key, required this.data});

  Color scoreColor(int score) {
    if (score >= 67) return Colors.green;
    if (score >= 34) return Colors.orange;
    return Colors.red;
  }

  Widget heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int score = data['score'];

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Text(
              '$score/100',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: scoreColor(score),
              ),
            ),
          ),
          Center(
            child: Text(
              'Patentability: ${data['verdict']}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),
          Text('Novelty: ${data['novelty']}/100'),
          Text('Inventive step: ${data['inventive_step']}/100'),
          heading('Invention'),
          Text(data['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(data['summary']),
          heading('Assessment'),
          Text(data['reasoning']),
          heading('Similar patents'),
          for (final p in data['similar_patents'])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${p['id']} - ${p['title']}'),
              subtitle: SelectableText(p['link']),
            ),
          heading('Recommendations'),
          for (final r in data['recommendations']) Text('• $r'),
          const SizedBox(height: 24),
          const Text(
            'This is an automated estimate, not legal advice.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}