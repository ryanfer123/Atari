import 'dart:typed_data';

/// Converts embedding vectors to and from the bytes stored in SQLite.
///
/// Little-endian float64, fixed width — so a blob's length is always
/// `dimensions * 8` and a truncated or foreign blob is detectable rather
/// than silently decoding into garbage that would then be compared as if
/// it were a real vector.
class EmbeddingCodec {
  const EmbeddingCodec._();

  static const bytesPerValue = 8;

  static Uint8List encode(List<double> vector) {
    final bytes = ByteData(vector.length * bytesPerValue);
    for (var i = 0; i < vector.length; i++) {
      bytes.setFloat64(i * bytesPerValue, vector[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  /// Returns null for a blob that isn't a whole number of float64s, or
  /// whose length disagrees with [expectedDimensions] — both mean the
  /// data didn't come from the embedder currently in use.
  static List<double>? decode(Uint8List? blob, {int? expectedDimensions}) {
    if (blob == null || blob.isEmpty) return null;
    if (blob.lengthInBytes % bytesPerValue != 0) return null;

    final length = blob.lengthInBytes ~/ bytesPerValue;
    if (expectedDimensions != null && length != expectedDimensions) return null;

    final bytes = ByteData.sublistView(blob);
    return [
      for (var i = 0; i < length; i++)
        bytes.getFloat64(i * bytesPerValue, Endian.little),
    ];
  }
}
