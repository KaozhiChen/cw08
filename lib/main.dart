import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

void main() {
  runApp(const MaterialApp(home: ImageLabelingPage()));
}

class ImageLabelingPage extends StatefulWidget {
  const ImageLabelingPage({super.key});

  @override
  _ImageLabelingPageState createState() => _ImageLabelingPageState();
}

class _ImageLabelingPageState extends State<ImageLabelingPage> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  Map<File, List<ImageLabel>> _imageLabels = {};

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles == null || pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images selected')),
      );
      return;
    }

    setState(() {
      _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      _imageLabels.clear();
    });

    for (var image in _selectedImages) {
      await _labelImage(image);
    }
  }

  Future<void> _labelImage(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    final imageLabeler = ImageLabeler(options: options);

    try {
      final labels = await imageLabeler.processImage(inputImage);
      setState(() {
        _imageLabels[image] = labels;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error labeling image: $e')),
      );
    } finally {
      imageLabeler.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Labeling')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImages,
              child: const Text('Select Images'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  final image = _selectedImages[index];
                  final labels = _imageLabels[image] ?? [];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.file(image, height: 200, fit: BoxFit.cover),
                        ...labels.map((label) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '${label.label} (${(label.confidence * 100).toStringAsFixed(2)}%)',
                              ),
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
