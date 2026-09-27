import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: CertificateUploadScreen(),
));

class CertificateUploadScreen extends StatefulWidget {
  const CertificateUploadScreen({super.key});

  @override
  State<CertificateUploadScreen> createState() =>
      _CertificateUploadScreenState();
}

class _CertificateUploadScreenState
    extends State<CertificateUploadScreen> {
  final Color primary = const Color(0xFFAD563E);
  final Color background = const Color(0xFFF7F0E7);
  final Color cardColor = const Color(0xFFFFFCF8);
  final Color borderColor = const Color(0xFFE2D5C8);
  final Color textColor = const Color(0xFF292522);
  final Color mutedColor = const Color(0xFF8B817A);

  final TextEditingController _titleController =
  TextEditingController();

  final TextEditingController _organizationController =
  TextEditingController();

  final TextEditingController _yearController =
  TextEditingController();

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

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _submitCertificate() {
    FocusScope.of(context).unfocus();
    _toast('Certificate submitted successfully');
  }

  // ================================================================
  // CERTIFICATE HELP
  // ================================================================

  void _showCertificateHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ==================================================
                // HELP HEADER
                // ==================================================

                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0DED4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: primary,
                        size: 26,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Certificate Help',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: mutedColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  'How to add a certificate?',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 14),

                // ==================================================
                // HELP ITEMS
                // ==================================================

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

                const SizedBox(height: 5),

                // ==================================================
                // IMPORTANT NOTE
                // ==================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0DED4),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: primary,
                        size: 20,
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          'Make sure the certificate is clear and the information is readable. Your certificate may be reviewed before appearing on your artist profile.',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // GOT IT BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Got It',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // HELP ITEM
  // ================================================================

  Widget _helpItem(
      IconData icon,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0DED4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 10.5,
                    height: 1.4,
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
  void dispose() {
    _titleController.dispose();
    _organizationController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textColor,
            size: 25,
          ),
          onPressed: () => _toast('Back clicked'),
        ),

        title: Text(
          'Certificates',
          style: TextStyle(
            color: textColor,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: textColor,
              size: 23,
            ),
            tooltip: 'Certificate Help',
            onPressed: _showCertificateHelp,
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  25,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    // ==================================================
                    // HEADER
                    // ==================================================

                    Text(
                      'Verify Your Skills',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Add your certificates to build trust and showcase your artistic expertise.',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // UPLOAD UI
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                          color: borderColor,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFFF0DED4),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.workspace_premium_outlined,
                              color: primary,
                              size: 37,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Text(
                            'Upload Certificate',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Add a certificate to your artist profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 17),

                          InkWell(
                            onTap: () =>
                                _toast('Certificate upload'),
                            borderRadius:
                            BorderRadius.circular(13),
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius:
                                BorderRadius.circular(13),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_rounded,
                                    color: Colors.white,
                                    size: 21,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Choose Certificate',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight:
                                      FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'PDF, JPG or PNG • Maximum 5 MB',
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // CERTIFICATE INFORMATION
                    // ==================================================

                    Text(
                      'Certificate Information',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 13),

                    _label('Certificate Name'),

                    const SizedBox(height: 6),

                    _textField(
                      controller: _titleController,
                      hint: 'Enter certificate name',
                      icon: Icons.badge_outlined,
                    ),

                    const SizedBox(height: 15),

                    _label('Issued By'),

                    const SizedBox(height: 6),

                    _textField(
                      controller: _organizationController,
                      hint: 'Enter organization / institute',
                      icon: Icons.business_outlined,
                    ),

                    const SizedBox(height: 15),

                    _label('Certificate Type'),

                    const SizedBox(height: 6),

                    _dropdownField(),

                    const SizedBox(height: 15),

                    _label('Year of Certification'),

                    const SizedBox(height: 6),

                    _textField(
                      controller: _yearController,
                      hint: 'e.g. 2025',
                      icon: Icons.calendar_today_outlined,
                      keyboardType:
                      TextInputType.number,
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // PREVIEW CARD
                    // ==================================================

                    Text(
                      'Certificate Preview',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius:
                        BorderRadius.circular(17),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFFF0DED4),
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: primary,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 13),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleController
                                      .text.isEmpty
                                      ? 'Certificate Name'
                                      : _titleController.text,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w800,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  _organizationController
                                      .text.isEmpty
                                      ? 'Issuing organization'
                                      : _organizationController.text,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 11,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_outlined,
                                      color: primary,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _yearController
                                          .text.isEmpty
                                          ? 'Year'
                                          : _yearController.text,
                                      style: TextStyle(
                                        color: primary,
                                        fontSize: 10,
                                        fontWeight:
                                        FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.edit_outlined,
                            color: mutedColor,
                            size: 19,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // VERIFICATION NOTE
                    // ==================================================

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0DED4),
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: primary,
                            size: 21,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'Your certificate may be reviewed before it appears on your artist profile.',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 11,
                                height: 1.4,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // SUBMIT BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitCertificate,
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Submit Certificate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: Text(
                        'You can add more certificates later.',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ========================================================
            // BOTTOM NAVIGATION
            // ========================================================

            _bottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // LABEL
  // ================================================================

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          color: textColor,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            icon,
            color: primary,
            size: 21,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: mutedColor.withValues(alpha: 0.75),
            fontSize: 13,
          ),
          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // DROPDOWN
  // ================================================================

  Widget _dropdownField() {
    return Container(
      height: 52,
      padding:
      const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: primary,
                size: 21,
              ),
              const SizedBox(width: 12),
              Text(
                'Select certificate type',
                style: TextStyle(
                  color:
                  mutedColor.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: mutedColor,
          ),
          dropdownColor: cardColor,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
          ),
          items: _certificateTypes
              .map(
                (type) => DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            ),
          )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value;
            });
          },
        ),
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _bottomNavigation() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            Icons.home_outlined,
            'Dashboard',
          ),

          _navItem(
            Icons.search_outlined,
            'Materials',
          ),

          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                  primary.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () =>
                  _toast('Add New Item'),
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          _navItem(
            Icons.receipt_long_outlined,
            'Orders',
          ),

          _navItem(
            Icons.person_outline_rounded,
            'Profile',
          ),
        ],
      ),
    );
  }

  Widget _navItem(
      IconData icon,
      String label,
      ) {
    return InkWell(
      onTap: () => _toast('$label clicked'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: mutedColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: mutedColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
