import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../widgets/back_button.dart';

/// Dedicated create/edit page for an artist's before-and-after portfolio story.
/// The Portfolio page remains the management screen; this page only handles add/edit.
class PortfolioEditorPage extends StatefulWidget {
  const PortfolioEditorPage({super.key, this.item});

  final Map<String, dynamic>? item;

  @override
  State<PortfolioEditorPage> createState() => _PortfolioEditorPageState();
}

class _PortfolioEditorPageState extends State<PortfolioEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = EcoLoopApi.instance;
  final _picker = ImagePicker();

  late final TextEditingController _title;
  late final TextEditingController _caption;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _materials;
  late final TextEditingController _process;
  late final TextEditingController _impact;
  late final TextEditingController _productId;

  XFile? _beforeFile;
  XFile? _afterFile;
  bool _featured = false;
  bool _saving = false;

  Map<String, dynamic>? get _item => widget.item;

  bool get _isEditing => _item != null;

  @override
  void initState() {
    super.initState();
    final item = _item ?? {};
    _title = TextEditingController(text: '${item['title'] ?? ''}');
    _caption = TextEditingController(text: '${item['caption'] ?? ''}');
    _description = TextEditingController(text: '${item['description'] ?? ''}');
    _category = TextEditingController(text: '${item['category'] ?? ''}');
    _materials = TextEditingController(text: '${item['materialsUsed'] ?? ''}');
    _process = TextEditingController(
      text: '${item['processDescription'] ?? ''}',
    );
    _impact = TextEditingController(
      text: '${item['environmentalImpact'] ?? ''}',
    );
    _productId = TextEditingController(text: '${item['productId'] ?? ''}');
    _featured =
        item['featured'] == true ||
        '${item['featured']}'.toLowerCase() == 'true';
  }

  @override
  void dispose() {
    _title.dispose();
    _caption.dispose();
    _description.dispose();
    _category.dispose();
    _materials.dispose();
    _process.dispose();
    _impact.dispose();
    _productId.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool before) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (!mounted || file == null) return;
      setState(() {
        if (before) {
          _beforeFile = file;
        } else {
          _afterFile = file;
        }
      });
    } catch (e) {
      if (!mounted) return;
      _message('Could not open image gallery: $e', error: true);
    }
  }

  String _mimeFor(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<Map<String, dynamic>> _imagePayload(XFile file, String prefix) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('$prefix image must be 5 MB or smaller.');
    }
    final mime = _mimeFor(file);
    final ext = mime == 'image/png'
        ? 'png'
        : mime == 'image/webp'
        ? 'webp'
        : mime == 'image/gif'
        ? 'gif'
        : 'jpg';
    return {
      'imageBase64${prefix}': base64Encode(bytes),
      'fileName${prefix}':
          '${prefix.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.$ext',
      'mimeType${prefix}': mime,
    };
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && (_beforeFile == null || _afterFile == null)) {
      _message('Please upload both before and after images.', error: true);
      return;
    }
    if (_isEditing) {
      final oldBefore = '${_item?['beforeImageUrl'] ?? ''}'.trim();
      final oldAfter =
          '${_item?['afterImageUrl'] ?? _item?['imageUrl'] ?? _item?['image'] ?? ''}'
              .trim();
      if (_beforeFile == null && oldBefore.isEmpty) {
        _message('Please add the before image.', error: true);
        return;
      }
      if (_afterFile == null && oldAfter.isEmpty) {
        _message('Please add the after image.', error: true);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'title': _title.text.trim(),
        'caption': _caption.text.trim(),
        'description': _description.text.trim(),
        'category': _category.text.trim(),
        'materialsUsed': _materials.text.trim(),
        'processDescription': _process.text.trim(),
        'environmentalImpact': _impact.text.trim(),
        'featured': _featured,
        if (_productId.text.trim().isNotEmpty)
          'productId':
              int.tryParse(_productId.text.trim()) ?? _productId.text.trim(),
      };

      if (_beforeFile != null)
        body.addAll(await _imagePayload(_beforeFile!, 'Before'));
      if (_afterFile != null)
        body.addAll(await _imagePayload(_afterFile!, 'After'));

      if (_isEditing) {
        final id = _item?['portfolioId'] ?? _item?['id'];
        if (id == null) throw Exception('Portfolio item ID is missing.');
        await _api.put('/artist/portfolio/$id', body);
      } else {
        await _api.post('/artist/portfolio', body);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted)
        _message(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? ArtistColors.error : ArtistColors.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton(),
        title: Text(
          _isEditing ? 'Edit Portfolio Work' : 'Add Portfolio Work',
          style: ArtistTextStyles.title,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _introCard(),
              const SizedBox(height: 20),
              Text(
                'Before & After',
                style: ArtistTextStyles.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 5),
              Text(
                'Show the original item and the finished transformation.',
                style: ArtistTextStyles.caption,
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _imagePicker(before: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _imagePicker(before: false)),
                ],
              ),
              const SizedBox(height: 22),
              _field(
                _title,
                'Project name *',
                'e.g. Reclaimed wooden lamp',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter a project name'
                    : null,
                maxLength: 150,
              ),
              _field(
                _caption,
                'Short caption',
                'A short line about the transformation',
                maxLength: 180,
              ),
              _field(
                _description,
                'Project story *',
                'Describe the original item and your finished work',
                minLines: 3,
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter the project story'
                    : null,
                maxLength: 5000,
              ),
              _field(
                _category,
                'Category *',
                'e.g. Home decor, Furniture, Art',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a category' : null,
                maxLength: 80,
              ),
              _field(
                _materials,
                'Materials reused',
                'List materials used in the project',
                minLines: 2,
                maxLines: 4,
              ),
              _field(
                _process,
                'Transformation process',
                'How did you make or restore it?',
                minLines: 3,
                maxLines: 5,
              ),
              _field(
                _impact,
                'Environmental impact',
                'What was reused, repaired or kept out of waste?',
                minLines: 2,
                maxLines: 4,
              ),
              _field(
                _productId,
                'Linked product ID (optional)',
                'Enter the EcoLoop product ID',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null &&
                      v.trim().isNotEmpty &&
                      int.tryParse(v.trim()) == null) {
                    return 'Product ID must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: ArtistColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ArtistColors.border),
                ),
                child: SwitchListTile(
                  value: _featured,
                  activeColor: ArtistColors.primary,
                  title: Text(
                    'Feature this project',
                    style: ArtistTextStyles.bodyMedium,
                  ),
                  subtitle: Text(
                    'Featured work appears first in your portfolio.',
                    style: ArtistTextStyles.caption,
                  ),
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _featured = v),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtistColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : (_isEditing
                              ? 'Save Changes'
                              : 'Publish Portfolio Work'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Images are uploaded to EcoLoop storage. JPG, PNG, WEBP and GIF up to 5 MB each.',
                textAlign: TextAlign.center,
                style: ArtistTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _introCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ArtistColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: ArtistColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ArtistColors.light,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_awesome_outlined,
            color: ArtistColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing
                    ? 'Update your story'
                    : 'Tell the story behind your work',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add the details buyers and other artists need to understand your creative process.',
                style: ArtistTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _imagePicker({required bool before}) {
    final file = before ? _beforeFile : _afterFile;
    final item = _item ?? {};
    final existing = before
        ? '${item['beforeImageUrl'] ?? ''}'
        : '${item['afterImageUrl'] ?? item['imageUrl'] ?? item['image'] ?? ''}';
    final label = before ? 'BEFORE IMAGE' : 'AFTER IMAGE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ArtistTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: ArtistColors.primary,
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: _saving ? null : () => _pickImage(before),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: ArtistColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (file != null)
                  Image.file(File(file.path), fit: BoxFit.cover)
                else if (existing.trim().isNotEmpty)
                  Image.network(
                    existing,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                else
                  _imagePlaceholder(),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: ArtistColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          file == null
              ? (existing.trim().isEmpty ? 'Tap to upload' : 'Tap to replace')
              : file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ArtistTextStyles.caption,
        ),
      ],
    );
  }

  Widget _imagePlaceholder() => Container(
    color: ArtistColors.light,
    child: const Center(
      child: Icon(Icons.image_outlined, size: 34, color: ArtistColors.primary),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    int minLines = 1,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: ArtistColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: ArtistColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: ArtistColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: ArtistColors.primary, width: 1.5),
        ),
        counterStyle: ArtistTextStyles.caption,
      ),
    ),
  );
}
