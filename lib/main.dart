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
  File? _selectedImage;
  List<ImageLabel> _labels = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
      return;
    }

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    await _labelImage(File(pickedFile.path));
  }

  Future<void> _labelImage(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    final imageLabeler = ImageLabeler(options: options);

    try {
      final List<ImageLabel> labels =
          await imageLabeler.processImage(inputImage);
      setState(() {
        _labels = labels;
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
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Select Image'),
          ),
          _selectedImage != null
              ? Image.file(_selectedImage!)
              : Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(child: Text('No image selected')),
                ),
          Expanded(
            child: ListView.builder(
              itemCount: _labels.length,
              itemBuilder: (context, index) {
                final label = _labels[index];
                return ListTile(
                  title: Text(label.label),
                  subtitle: Text(
                    'Confidence: ${(label.confidence * 100).toStringAsFixed(2)}%',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
