import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SelectedEcoImage {
  final XFile file;
  final Uint8List bytes;
  const SelectedEcoImage(this.file, this.bytes);

  Future<Map<String, dynamic>> toApiPayload() async => {
    'base64': base64Encode(bytes),
    'fileName': file.name,
    'mimeType': mimeType,
  };

  String get mimeType {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

class EcoImagePicker {
  static final ImagePicker _picker = ImagePicker();
  static const int maxBytes = 5 * 1024 * 1024;

  static Future<List<SelectedEcoImage>> pick({
    List<SelectedEcoImage> current = const [],
    int maxImages = 4,
    ImageSource source = ImageSource.gallery,
  }) async {
    final remaining = maxImages - current.length;
    if (remaining <= 0) return current;
    List<XFile> files;
    if (source == ImageSource.gallery) {
      files = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
    } else {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      files = file == null ? <XFile>[] : <XFile>[file];
    }
    final result = [...current];
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      if (bytes.length > maxBytes) {
        throw Exception(
          '${file.name} is larger than 5 MB. Please select a smaller image.',
        );
      }
      result.add(SelectedEcoImage(file, bytes));
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>> payload(
    List<SelectedEcoImage> images,
  ) async {
    final items = <Map<String, dynamic>>[];
    for (final image in images) {
      items.add(await image.toApiPayload());
    }
    return items;
  }

  static Widget gallery({
    required BuildContext context,
    required List<SelectedEcoImage> images,
    required ValueChanged<List<SelectedEcoImage>> onChanged,
    int maxImages = 4,
    Color accent = const Color(0xFF2A4D3A),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...images.asMap().entries.map(
              (entry) => Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      entry.value.bytes,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: InkWell(
                      onTap: () => onChanged([...images]..removeAt(entry.key)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (images.length < maxImages)
              InkWell(
                onTap: () async {
                  final choice = await showModalBottomSheet<ImageSource>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_library_outlined),
                            title: const Text('Choose from gallery'),
                            onTap: () =>
                                Navigator.pop(ctx, ImageSource.gallery),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_camera_outlined),
                            title: const Text('Take a photo'),
                            onTap: () => Navigator.pop(ctx, ImageSource.camera),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (choice == null) return;
                  try {
                    final picked = await pick(
                      current: images,
                      maxImages: maxImages,
                      source: choice,
                    );
                    onChanged(picked);
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                  }
                },
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withOpacity(.45),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: accent,
                    size: 27,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${images.length}/$maxImages photos selected • Max 5 MB each',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
