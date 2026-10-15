import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';

/// Stores the artist's certificate metadata and file in the backend.
/// The form is prefilled from the Artists sheet and never shows sample data.
class Certification extends StatefulWidget {
  const Certification({super.key});

  @override
  State<Certification> createState() => _CertificationState();
}

class _CertificationState extends State<Certification> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _organizationController = TextEditingController();
  final _typeController = TextEditingController();
  final _yearController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _certificateUrl = '';
  String _existingFileName = '';
  String? _pickedFileName;
  String? _pickedMimeType;
  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    _loadCertificate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _organizationController.dispose();
    _typeController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  String _text(dynamic value) {
    final result = value?.toString().trim() ?? '';
    return result.toLowerCase() == 'null' ? '' : result;
  }

  Future<void> _loadCertificate() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final data = _map(await _api.get('/artist/certification'));
      if (!mounted) return;
      setState(() {
        _titleController.text = _text(data['certificationTitle']);
        _organizationController.text = _text(data['certificationOrganization']);
        _typeController.text = _text(data['certificationType']);
        _yearController.text = _text(data['certificationYear']);
        _certificateUrl = _text(data['certificationUrl']);
        _existingFileName = _text(data['certificationFileName']);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage(
          'The selected file could not be read. Please try another file.',
        );
        return;
      }
      if (bytes.length > 10 * 1024 * 1024) {
        _showMessage(
          'The selected file is larger than 10 MB. Please choose a smaller file.',
        );
        return;
      }

      final extension = (file.extension ?? '').toLowerCase();
      String mimeType;
      if (extension == 'pdf') {
        mimeType = 'application/pdf';
      } else if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      } else {
        mimeType = 'application/octet-stream';
      }

      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedFileName = file.name;
        _pickedMimeType = mimeType;
      });
    } catch (error) {
      _showMessage('Could not select the certificate: $error');
    }
  }

  Future<void> _submitCertificate() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_pickedBytes == null && _certificateUrl.isEmpty) {
      _showMessage('Please choose a certificate file before saving.');
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'certificationTitle': _titleController.text.trim(),
        'certificationOrganization': _organizationController.text.trim(),
        'certificationType': _typeController.text.trim(),
        'certificationYear': _yearController.text.trim(),
      };
      if (_pickedBytes != null) {
        payload.addAll({
          'base64': base64Encode(_pickedBytes!),
          'fileName': _pickedFileName,
          'mimeType': _pickedMimeType,
        });
      }

      final response = _map(await _api.post('/artist/certification', payload));
      if (!mounted) return;
      setState(() {
        _certificateUrl = _text(response['certificationUrl']).isNotEmpty
            ? _text(response['certificationUrl'])
            : _certificateUrl;
        _existingFileName = _text(response['certificationFileName']).isNotEmpty
            ? _text(response['certificationFileName'])
            : (_pickedFileName ?? _existingFileName);
        _pickedBytes = null;
        _pickedFileName = null;
        _pickedMimeType = null;
        _saving = false;
      });
      _showMessage('Certificate details saved successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save certificate: $error');
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArtistColors.surface,
        title: const Text('Certificate Help'),
        content: const Text(
          'Enter the details shown on your certificate, then upload a PDF, JPG, JPEG, or PNG file. The file is stored in Google Drive and its URL and metadata are saved to the Artists sheet. Maximum file size: 10 MB.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.accent,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
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
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
            size: 23,
          ),
        ),
        title: Text(
          'Certificates',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Certificate help',
            onPressed: _showHelp,
            icon: const Icon(
              Icons.help_outline_rounded,
              color: ArtistColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildUploadCard(),
                      const SizedBox(height: 20),
                      _buildInformationSection(),
                      const SizedBox(height: 18),
                      _buildVerificationNote(),
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: ArtistColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body.copyWith(height: 1.4),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _loadCertificate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Your Skills',
          style: ArtistTextStyles.heading.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Add your real certificate details and document to your artist profile.',
          style: ArtistTextStyles.body.copyWith(fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildUploadCard() {
    final selectedName = _pickedFileName ?? _existingFileName;
    final hasFile = _pickedBytes != null || _certificateUrl.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withOpacity(0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              hasFile
                  ? Icons.verified_outlined
                  : Icons.workspace_premium_outlined,
              color: ArtistColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasFile ? 'Certificate selected' : 'Upload Certificate',
            style: ArtistTextStyles.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            selectedName.isNotEmpty
                ? selectedName
                : 'Choose a file from your device',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ArtistTextStyles.caption.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _pickCertificate,
              icon: const Icon(Icons.upload_rounded, size: 19),
              label: Text(
                _pickedFileName == null
                    ? 'Choose Certificate'
                    : 'Change Selected File',
                style: ArtistTextStyles.button.copyWith(fontSize: 12.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PDF, JPG, JPEG or PNG • Maximum 10 MB',
            style: ArtistTextStyles.caption.copyWith(fontSize: 9.5),
          ),
          if (_certificateUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showCertificateLink(),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('View saved certificate link'),
            ),
          ],
        ],
      ),
    );
  }

  void _showCertificateLink() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArtistColors.surface,
        title: const Text('Saved certificate'),
        content: SelectableText(_certificateUrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificate Information',
          style: ArtistTextStyles.title.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 11),
        _label('Certificate Name'),
        const SizedBox(height: 5),
        _textField(
          controller: _titleController,
          hint: 'Enter certificate name',
          icon: Icons.badge_outlined,
          validator: (value) => (value ?? '').trim().isEmpty
              ? 'Certificate name is required.'
              : null,
        ),
        const SizedBox(height: 12),
        _label('Issued By'),
        const SizedBox(height: 5),
        _textField(
          controller: _organizationController,
          hint: 'Enter organization / institute',
          icon: Icons.business_outlined,
          validator: (value) => (value ?? '').trim().isEmpty
              ? 'Issuing organization is required.'
              : null,
        ),
        const SizedBox(height: 12),
        _label('Certificate Type'),
        const SizedBox(height: 5),
        _textField(
          controller: _typeController,
          hint: 'Enter certificate type',
          icon: Icons.category_outlined,
          validator: (value) => (value ?? '').trim().isEmpty
              ? 'Certificate type is required.'
              : null,
        ),
        const SizedBox(height: 12),
        _label('Year of Certification'),
        const SizedBox(height: 5),
        _textField(
          controller: _yearController,
          hint: 'YYYY',
          icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.number,
          validator: (value) {
            final year = int.tryParse((value ?? '').trim());
            final currentYear = DateTime.now().year;
            if (year == null || year < 1900 || year > currentYear) {
              return 'Enter a valid year between 1900 and $currentYear.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVerificationNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: ArtistColors.primary,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'The details and file are saved to your artist record. Upload only a genuine certificate. Review or verification status is not shown because the current backend does not provide a verification workflow.',
              style: ArtistTextStyles.body.copyWith(
                color: ArtistColors.textPrimary,
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saving ? null : _submitCertificate,
        style: ElevatedButton.styleFrom(
          backgroundColor: ArtistColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ArtistColors.primary.withOpacity(0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Save Certificate',
                style: ArtistTextStyles.button.copyWith(fontSize: 13),
              ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: ArtistTextStyles.label.copyWith(fontSize: 11.5));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: ArtistTextStyles.body.copyWith(
        color: ArtistColors.textPrimary,
        fontSize: 12.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: ArtistTextStyles.hint.copyWith(fontSize: 12),
        prefixIcon: Icon(icon, color: ArtistColors.primary, size: 20),
        filled: true,
        fillColor: ArtistColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ArtistColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ArtistColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ArtistColors.primary, width: 1.2),
        ),
        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
}
