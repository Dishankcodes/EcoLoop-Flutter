import 'dart:convert';

/// Normalizes image URLs returned by the EcoLoop API.
///
/// Google Drive share/viewer URLs are not image endpoints. For files that have
/// been shared as "Anyone with the link", this converts supported Drive URL
/// forms to the direct-view endpoint used by the existing app.
class EcoImageUrl {
  EcoImageUrl._();

  static String normalize(String? rawValue) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) return '';

    final uri = Uri.tryParse(value);
    if (uri == null) return value;

    final host = uri.host.toLowerCase();
    if (host != 'drive.google.com' &&
        host != 'www.drive.google.com' &&
        host != 'docs.google.com' &&
        host != 'www.docs.google.com') {
      return value;
    }

    String? fileId = uri.queryParameters['id'];

    final segments = uri.pathSegments;
    final fileIndex = segments.indexOf('d');
    if ((fileId == null || fileId.isEmpty) &&
        segments.isNotEmpty &&
        segments.first == 'file' &&
        segments.length >= 3 &&
        segments[1] == 'd') {
      fileId = segments[2];
    } else if ((fileId == null || fileId.isEmpty) &&
        fileIndex >= 0 &&
        fileIndex + 1 < segments.length) {
      fileId = segments[fileIndex + 1];
    }

    if (fileId == null || fileId.trim().isEmpty) return value;
    return 'https://drive.google.com/uc?export=view&id=${Uri.encodeQueryComponent(fileId.trim())}';
  }

  /// Recursively normalizes URL strings inside API payloads, including URLs
  /// inside JSON-encoded image-list fields, without changing map/list shapes.
  static dynamic normalizePayload(dynamic value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key, normalizePayload(item)));
    }

    if (value is List) {
      return value.map<dynamic>(normalizePayload).toList();
    }

    if (value is! String) return value;

    final text = value.trim();
    if (text.isEmpty) return value;

    // Some Sheets columns store image arrays as JSON text instead of a JSON
    // array. Normalize inside that string but preserve its original type.
    if ((text.startsWith('[') && text.endsWith(']')) ||
        (text.startsWith('{') && text.endsWith('}'))) {
      try {
        final decoded = jsonDecode(text);
        final normalized = normalizePayload(decoded);
        return jsonEncode(normalized);
      } catch (_) {
        // It is ordinary text rather than valid JSON; handle URL below.
      }
    }

    if (text.contains('drive.google.com') || text.contains('docs.google.com')) {
      return _normalizeDriveUrlsInsideText(value);
    }
    return value;
  }

  static String _normalizeDriveUrlsInsideText(String input) {
    // This supports direct URLs and JSON-escaped URLs in stringified arrays.
    final pattern = RegExp(
      r"""https?://(?:drive|docs)\.google\.com/[^"\s,}\]]+""",
      caseSensitive: false,
    );
    return input.replaceAllMapped(pattern, (match) {
      var candidate = match.group(0) ?? '';
      candidate = candidate.replaceAll(r'\/', '/');
      // Trim punctuation that is not part of a URL.
      while (candidate.isNotEmpty &&
          (candidate.endsWith('.') ||
              candidate.endsWith(';') ||
              candidate.endsWith(')'))) {
        candidate = candidate.substring(0, candidate.length - 1);
      }
      return normalize(candidate);
    });
  }
}
