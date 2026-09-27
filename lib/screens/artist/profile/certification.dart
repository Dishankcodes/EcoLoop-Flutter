import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class Certification extends StatefulWidget {
  const Certification({super.key});

  @override
  State<Certification> createState() => _CertificationState();
}

class _CertificationState extends State<Certification> {
  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _organizationController = TextEditingController();

  final TextEditingController _yearController = TextEditingController();

  String? _selectedType;

  final List<String> _certificateTypes = [
    'Art & Craft',
    'Handicraft',
    'Design',
    'Painting',
    'Woodwork',
    'Sculpture',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _titleController.addListener(_refreshPreview);
    _organizationController.addListener(_refreshPreview);
    _yearController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshPreview);
    _organizationController.removeListener(_refreshPreview);
    _yearController.removeListener(_refreshPreview);

    _titleController.dispose();
    _organizationController.dispose();
    _yearController.dispose();

    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  // Submit certificate.
  void _submitCertificate() {
    FocusScope.of(context).unfocus();

    if (_titleController.text.trim().isEmpty) {
      _showMessage('Please enter the certificate name.');
      return;
    }

    if (_organizationController.text.trim().isEmpty) {
      _showMessage('Please enter the issuing organization.');
      return;
    }

    if (_selectedType == null) {
      _showMessage('Please select a certificate type.');
      return;
    }

    if (_yearController.text.trim().isEmpty) {
      _showMessage('Please enter the certification year.');
      return;
    }

    _showMessage('Certificate submitted successfully.');
  }

  // Certificate help.
  void _showCertificateHelp() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ArtistColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ArtistColors.light,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: ArtistColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Certificate Help',
                          style: ArtistTextStyles.title.copyWith(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: ArtistColors.textSecondary,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'How to add a certificate?',
                    style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  _helpItem(
                    Icons.badge_outlined,
                    'Certificate Name',
                    'Enter the official name written on your certificate.',
                  ),
                  _helpItem(
                    Icons.business_outlined,
                    'Issued By',
                    'Enter the organization, institute, or authority that issued the certificate.',
                  ),
                  _helpItem(
                    Icons.category_outlined,
                    'Certificate Type',
                    'Select the category that best matches your certificate.',
                  ),
                  _helpItem(
                    Icons.calendar_today_outlined,
                    'Certification Year',
                    'Enter the year in which you received the certificate.',
                  ),
                  _helpItem(
                    Icons.upload_file_outlined,
                    'Certificate File',
                    'Upload a clear PDF, JPG, or PNG certificate. Maximum file size is 5 MB.',
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ArtistColors.light,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: ArtistColors.primary,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Make sure the certificate is clear and the information is readable. Your certificate may be reviewed before appearing on your artist profile.',
                            style: ArtistTextStyles.body.copyWith(
                              color: ArtistColors.textPrimary,
                              fontSize: 10.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtistColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: Text(
                        'Got It',
                        style: ArtistTextStyles.button.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Help item.
  Widget _helpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ArtistColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 11.5),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: ArtistTextStyles.caption.copyWith(
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          onPressed: () {
            Navigator.pop(context);
          },
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
            tooltip: 'Certificate Help',
            onPressed: _showCertificateHelp,
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
              const SizedBox(height: 20),
              _buildPreviewSection(),
              const SizedBox(height: 18),
              _buildVerificationNote(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'You can add more certificates later.',
                  style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header.
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
          'Add your certificates to build trust and showcase your artistic expertise.',
          style: ArtistTextStyles.body.copyWith(fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  // Upload card.
  Widget _buildUploadCard() {
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
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: ArtistColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload Certificate',
            style: ArtistTextStyles.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a certificate to your artist profile',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                _showMessage(
                  'Certificate upload will be connected in the next phase.',
                );
              },
              icon: const Icon(Icons.upload_rounded, size: 19),
              label: Text(
                'Choose Certificate',
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
            'PDF, JPG or PNG • Maximum 5 MB',
            style: ArtistTextStyles.caption.copyWith(fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  // Certificate information.
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
        ),
        const SizedBox(height: 12),
        _label('Issued By'),
        const SizedBox(height: 5),
        _textField(
          controller: _organizationController,
          hint: 'Enter organization / institute',
          icon: Icons.business_outlined,
        ),
        const SizedBox(height: 12),
        _label('Certificate Type'),
        const SizedBox(height: 5),
        _dropdownField(),
        const SizedBox(height: 12),
        _label('Year of Certification'),
        const SizedBox(height: 5),
        _textField(
          controller: _yearController,
          hint: 'e.g. 2025',
          icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // Preview.
  Widget _buildPreviewSection() {
    final title = _titleController.text.trim();
    final organization = _organizationController.text.trim();
    final year = _yearController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificate Preview',
          style: ArtistTextStyles.title.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ArtistColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: ArtistColors.primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Certificate Name' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      organization.isEmpty
                          ? 'Issuing organization'
                          : organization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          color: ArtistColors.primary,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          year.isEmpty ? 'Year' : year,
                          style: ArtistTextStyles.caption.copyWith(
                            color: ArtistColors.primary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedType != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: ArtistColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              _selectedType!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ArtistTextStyles.caption.copyWith(
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.edit_outlined,
                color: ArtistColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Verification note.
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
              'Your certificate may be reviewed before it appears on your artist profile.',
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

  // Submit button.
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitCertificate,
        style: ElevatedButton.styleFrom(
          backgroundColor: ArtistColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Submit Certificate',
          style: ArtistTextStyles.button.copyWith(fontSize: 13),
        ),
      ),
    );
  }

  // Field label.
  Widget _label(String text) {
    return Text(text, style: ArtistTextStyles.label.copyWith(fontSize: 11.5));
  }

  // Text field.
  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
      ),
    );
  }

  // Certificate dropdown.
  Widget _dropdownField() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtistColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(
                Icons.category_outlined,
                color: ArtistColors.primary,
                size: 20,
              ),
              const SizedBox(width: 11),
              Text(
                'Select certificate type',
                style: ArtistTextStyles.hint.copyWith(fontSize: 12),
              ),
            ],
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ArtistColors.textSecondary,
          ),
          dropdownColor: ArtistColors.surface,
          style: ArtistTextStyles.body.copyWith(
            color: ArtistColors.textPrimary,
            fontSize: 12.5,
          ),
          borderRadius: BorderRadius.circular(12),
          items: _certificateTypes.map((type) {
            return DropdownMenuItem<String>(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value;
            });
          },
        ),
      ),
    );
  }

  // Snackbar.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.body.copyWith(
              color: Colors.white,
              fontSize: 11.5,
            ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.accent,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      );
  }
}
