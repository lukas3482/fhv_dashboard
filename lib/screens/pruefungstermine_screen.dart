import 'package:flutter/material.dart';

import '../models/exam_appointment.dart';
import '../services/exam_service.dart';
import '../widgets/pruefungstermine/exam_card.dart';
import '../widgets/pruefungstermine/section_header.dart';

class PruefungstermineScreen extends StatefulWidget {
  const PruefungstermineScreen({super.key});

  @override
  State<PruefungstermineScreen> createState() => _PruefungstermineScreenState();
}

class _PruefungstermineScreenState extends State<PruefungstermineScreen> {
  late Future<List<ExamAppointment>> _future;

  @override
  void initState() {
    super.initState();
    _future = ExamService().fetchExams();
  }

  void _refresh() {
    setState(() {
      _future = ExamService().fetchExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExamAppointment>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _refresh,
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          );
        }

        final all = snapshot.data!;
        if (all.isEmpty) {
          return const Center(child: Text('Keine Prüfungstermine gefunden.'));
        }

        final upcoming = all.where((e) => !e.isPast).toList();
        final past = all.where((e) => e.isPast).toList();

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              if (upcoming.isNotEmpty) ...[
                SectionHeader('Bevorstehend', upcoming.length),
                ...upcoming.map((e) => ExamCard(exam: e)),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 8),
                SectionHeader('Vergangen', past.length),
                ...past.map((e) => ExamCard(exam: e, dimmed: true)),
              ],
            ],
          ),
        );
      },
    );
  }
}
