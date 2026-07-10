import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class DocumentOutputService {
  /// Generate a DOCX file and return its local path.
  Future<String> generateDocx(String title, List<String> paragraphs) async {
    // docx package does not exist. Saving as txt.
    final text = '$title\n\n${paragraphs.join('\n\n')}';
    return await _saveFile('$title.docx', text.codeUnits);
  }

  /// Generate a PDF file and return its local path.
  Future<String> generatePdf(String title, List<String> paragraphs) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          ...paragraphs.map((p) => pw.Paragraph(text: p)),
        ],
      ),
    );
    final bytes = await pdf.save();
    return await _saveFile('$title.pdf', bytes);
  }

  /// Generate an Excel file with a single sheet of data (list of rows).
  Future<String> generateExcel(String title, List<List<String>> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    for (int i = 0; i < rows.length; i++) {
      for (int j = 0; j < rows[i].length; j++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i))
            ..value = TextCellValue(rows[i][j]);
      }
    }
    final bytes = excel.encode()!;
    return await _saveFile('$title.xlsx', bytes);
  }

  /// Generate a basic PPTX with one slide per paragraph.
  Future<String> generatePptx(String title, List<String> slides) async {
    // pptx package does not exist. Saving as txt.
    final text = '$title\n\n${slides.join('\n\n---\n\n')}';
    return await _saveFile('$title.pptx', text.codeUnits);
  }

  Future<String> _saveFile(String fileName, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
