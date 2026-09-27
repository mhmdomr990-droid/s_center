import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';


class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfViewerPage({super.key, required this.filePath, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfController? _controller;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _openDocument();
  }

  void _openDocument() {
    _controller?.dispose();
    _controller = PdfController(
      document: PdfDocument.openFile(widget.filePath),
    );
    _error = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        actions: [
          if (!_error)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ValueListenableBuilder<int>(
                  valueListenable: controller!.pageListenable,
                  builder: (_, page, _) {
                    final total = controller.pagesCount;
                    return Text(
                      total != null ? '$page / $total' : '$page',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      body: _error || controller == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white54, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'تعذر فتح ملف PDF',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(_openDocument);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('إعادة المحاولة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                  ),
                ],
              ),
            )
          : PdfView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              pageSnapping: true,
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
              onPageChanged: (_) {},
              onDocumentLoaded: (_) => setState(() {}),
              onDocumentError: (_) {
                if (mounted) setState(() => _error = true);
              },
            ),
    );
  }
}
