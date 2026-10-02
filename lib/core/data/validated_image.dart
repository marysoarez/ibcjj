import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../errors/app_failure.dart';

class ValidatedImage {
  static const maxBytes = 5 * 1024 * 1024;
  static const maxDimension = 8192;
  static const maxPixels = 20000000;
  final Uint8List bytes;
  final String contentType;
  const ValidatedImage(this.bytes, this.contentType);

  static Future<ValidatedImage?> pick(ImagePicker picker) async {
    try {
      final image = await picker.pickImage(source: ImageSource.gallery);
      return image == null ? null : await read(image);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure('image-selection',
          'Não foi possível abrir a imagem. Verifique a permissão de fotos nas configurações.');
    }
  }

  static Future<ValidatedImage> read(XFile image) async {
    if (await image.length() > maxBytes) {
      throw const AppFailure('image-size', 'Escolha uma imagem de até 5 MB.');
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in image.openRead()) {
      if (builder.length + chunk.length > maxBytes) {
        throw const AppFailure('image-size', 'Escolha uma imagem de até 5 MB.');
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    final String mime;
    if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71 &&
        bytes[4] == 13 &&
        bytes[5] == 10 &&
        bytes[6] == 26 &&
        bytes[7] == 10) {
      mime = 'image/png';
    } else if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      mime = 'image/jpeg';
    } else if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      mime = 'image/webp';
    } else {
      throw const AppFailure(
          'image-format', 'Use uma imagem JPEG, PNG ou WebP.');
    }

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > maxDimension ||
          descriptor.height > maxDimension ||
          descriptor.width * descriptor.height > maxPixels) {
        throw const AppFailure('image-dimensions',
            'Escolha uma imagem de até 20 megapixels e 8192 pixels por lado.');
      }
      codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure('image-invalid',
          'Não foi possível ler a imagem. Escolha outro arquivo.');
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
    return ValidatedImage(bytes, mime);
  }
}
