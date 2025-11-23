import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../screens/camera_screen.dart';

enum ImageFilterType { none, grayscale, sepia }

class CameraService {
  static final CameraService instance = CameraService._init();
  CameraService._init();

  List<CameraDescription>? _cameras;
  final ImagePicker _picker = ImagePicker();

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      _cameras = [];
    }
  }

  bool get hasCameras => _cameras != null && _cameras!.isNotEmpty;

  Future<String?> takePicture(BuildContext context) async {
    if (!hasCameras) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Nenhuma câmera disponível'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    final camera = _cameras!.first;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!context.mounted) return null;

      final imagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(controller: controller),
          fullscreenDialog: true,
        ),
      );

      return imagePath;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir câmera'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      controller.dispose();
    }
  }

  Future<String?> pickFromGallery(BuildContext context) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
      );
      if (picked == null) return null;
      final savedPath = await savePicture(picked);
      return savedPath;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao acessar a galeria'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<String> savePicture(XFile image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'task_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savePath = path.join(appDir.path, 'images', fileName);

    final imageDir = Directory(path.join(appDir.path, 'images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final savedImage = await File(image.path).copy(savePath);
    return savedImage.path;
  }

  Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String> applyFilterAndResave(String sourcePath, ImageFilterType filter) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Falha ao decodificar imagem.');
    }

    img.Image processed = decoded;
    switch (filter) {
      case ImageFilterType.grayscale:
        processed = img.grayscale(processed);
        break;
      case ImageFilterType.sepia:
        processed = img.sepia(processed);
        break;
      case ImageFilterType.none:
        break;
    }

    final outJpg = img.encodeJpg(processed, quality: 90);

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final destPath = path.join(imagesDir.path, 'filtered_$ts.jpg');

    await File(destPath).writeAsBytes(outJpg);
    return destPath;
  }
}
