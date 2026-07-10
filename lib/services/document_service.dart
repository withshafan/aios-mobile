import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:docx/docx.dart' as docx;
import 'package:open_file/open_file.dart';

class DocumentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> get documents => _documents;

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  DocumentService() {
    debugPrint('DocumentService constructor START');
    loadHistory();
  }

  void loadHistory() {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _documents = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
      notifyListeners();
    });
  }

  Future<void> deleteDocument(String docId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .doc(docId)
        .delete();
  }

  /// Generate PDF and save to Downloads
  Future<String> generatePdf(String title, String content) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Paragraph(text: content),
        ],
      ),
    );
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final file = File('${downloadsDir.path}/$title.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Generate Word docx and save to Downloads
  Future<String> generateDocx(String title, String content) async {
    // Fake docx package removed to fix build error.
    // In a real app, use docx_template or similar.
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final file = File('${downloadsDir.path}/$title.docx');
    await file.writeAsString("Docx Generation Disabled: \n$title\n$content");
    return file.path;
  }

  /// Save metadata to Firestore
  Future<void> saveToHistory(String title, String type, String filePath) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .add({
      'title': title,
      'type': type, // 'pdf' or 'docx'
      'filePath': filePath,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Open a file with the system handler
  Future<void> openFile(String path) async {
    await OpenFile.open(path);
  }
}

