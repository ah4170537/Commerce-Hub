import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const _imgBbApiKey = String.fromEnvironment('IMGBB_API_KEY');

abstract interface class ProductEditorRepository {
  Future<void> updateProduct({
    required String productId,
    required Map<String, dynamic> fields,
    required List<String> retainedImageUrls,
    required List<XFile> addedImages,
  });
}

class ProductImageUploadException implements Exception {
  final String message;

  const ProductImageUploadException(this.message);

  @override
  String toString() => message;
}

class ImgBBImageUploader {
  final http.Client _httpClient;
  final String apiKey;

  ImgBBImageUploader({http.Client? httpClient, String? apiKey})
    : _httpClient = httpClient ?? http.Client(),
      apiKey = _resolveApiKey(apiKey);

  Future<String> upload(String fileName, Uint8List bytes) async {
    if (apiKey.isEmpty) {
      throw const ProductImageUploadException(
        'ImgBB API key is missing. Run the app with '
        '--dart-define=IMGBB_API_KEY=YOUR_KEY.',
      );
    }
    if (bytes.isEmpty) {
      throw ProductImageUploadException(
        'Selected image "${fileName.isEmpty ? 'image' : fileName}" is empty.',
      );
    }

    final uri = Uri.https('api.imgbb.com', '/1/upload', {'key': apiKey});
    try {
      final response = await _httpClient.post(
        uri,
        body: {'image': base64Encode(bytes), 'name': fileName},
      );
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> &&
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['success'] == true &&
          decoded['data'] is Map<String, dynamic>) {
        final url = (decoded['data'] as Map<String, dynamic>)['url'];
        if (url is String && url.isNotEmpty) return url;
      }

      final errorData = decoded is Map<String, dynamic>
          ? decoded['error']
          : null;
      final errorMessage = errorData is Map<String, dynamic>
          ? errorData['message']
          : null;
      throw ProductImageUploadException(
        'ImgBB rejected "${fileName.isEmpty ? 'image' : fileName}" '
        '(${response.statusCode}): '
        '${errorMessage is String ? errorMessage : response.body}',
      );
    } on ProductImageUploadException {
      rethrow;
    } on FormatException catch (error) {
      throw ProductImageUploadException(
        'ImgBB returned an invalid response for the image upload: $error',
      );
    } on http.ClientException catch (error) {
      throw ProductImageUploadException(
        'Could not connect to ImgBB while uploading the image: $error',
      );
    }
  }
}

String _resolveApiKey(String? suppliedKey) {
  if (suppliedKey != null) return suppliedKey;
  final dotenvKey = dotenv.env['IMGBB_API_KEY'];
  if (dotenvKey != null && dotenvKey.trim().isNotEmpty) {
    return dotenvKey.trim();
  }
  return _imgBbApiKey;
}

class ImgBBProductEditorRepository implements ProductEditorRepository {
  final FirebaseFirestore _firestore;
  final ImgBBImageUploader _imageUploader;

  ImgBBProductEditorRepository({
    FirebaseFirestore? firestore,
    ImgBBImageUploader? imageUploader,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _imageUploader = imageUploader ?? ImgBBImageUploader();

  @override
  Future<void> updateProduct({
    required String productId,
    required Map<String, dynamic> fields,
    required List<String> retainedImageUrls,
    required List<XFile> addedImages,
  }) async {
    final uploadedUrls = <String>[];
    for (final image in addedImages) {
      final Uint8List bytes = await image.readAsBytes();
      uploadedUrls.add(await _imageUploader.upload(image.name, bytes));
    }

    final productReference = _firestore.collection('products').doc(productId);
    await productReference.update({
      ...fields,
      'id': productId,
      'imageUrls': [...retainedImageUrls, ...uploadedUrls],
      'imageStoragePaths': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
