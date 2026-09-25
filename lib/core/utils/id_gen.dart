import 'dart:math';

/// Client-side identifiers for records created offline.
///
/// A record registered in a village with no signal needs an identity before the
/// server ever sees it: the QR code is printed and handed to the caregiver on
/// the spot. These ids travel with the record to /sync/upload as `clientUuid`,
/// and the server uses them to de-duplicate re-uploads.
class IdGen {
  IdGen._();

  static final Random _rng = Random.secure();

  static const _hex = '0123456789abcdef';

  /// RFC-4122 version 4 UUID.
  static String uuid() {
    final b = List<int>.generate(16, (_) => _rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 10xx
    final s = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) s.write('-');
      s
        ..write(_hex[(b[i] >> 4) & 0x0f])
        ..write(_hex[b[i] & 0x0f]);
    }
    return s.toString();
  }

  /// Short, human-readable child code — `SSD-7K4M-2Q9X`.
  ///
  /// Ambiguous glyphs (0/O, 1/I) are excluded so a code read off a smudged
  /// printout or dictated over a phone line survives the trip.
  static String childCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String block() => List.generate(
        4, (_) => alphabet[_rng.nextInt(alphabet.length)]).join();
    return 'SSD-${block()}-${block()}';
  }

  /// The payload encoded into a child's printed QR code.
  static String qrPayload(String code) => 'SALAMA:CHILD:$code';
}
