import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 300),
        sendTimeout: const Duration(seconds: 300),
        headers: {
          'Connection': 'close',
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (log) => debugPrint('[API] $log'),
        ),
      );
    }
  }

  // AUTH

  Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      debugPrint('[API] Login: username=$username');
      final response = await dio.post(
        ApiConstants.login,
        data: {
          "username": username,
          "password": password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('[API] Login error: ${e.type} ${e.response?.statusCode}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      debugPrint('[API] Register: username=$username email=$email');
      final response = await dio.post(
        ApiConstants.register,
        data: {
          "nama": nama,
          "email": email,
          "username": username,
          "password": password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('[API] Register error: ${e.type} ${e.response?.statusCode}');
      rethrow;
    }
  }

  // FASHION

  /// Upload gambar dan dapatkan id_item dari backend.
  /// Backend otomatis mengekstrak embedding (ResNet50) dan
  /// meng-classify kategori pakaian.
  Future<int> uploadImage({
    required File image,
    String? namaItem,
    String? subCategory,
    int? idCategory,
    int? idColor,
    String? pattern,
  }) async {
    debugPrint('[API] Upload gambar: ${image.path}');

    final String fileName = image.path.split('/').last;

    final dataMap = <String, dynamic>{
      "image": await MultipartFile.fromFile(
        image.path,
        filename: fileName,
      ),
      "source_type": "upload",
    };

    if (namaItem != null && namaItem.isNotEmpty) {
      dataMap["nama_item"] = namaItem;
    }
    if (idCategory != null) {
      dataMap["id_category"] = idCategory.toString();
    }
    if (idColor != null) {
      dataMap["id_color"] = idColor.toString();
    }
    if (pattern != null) {
      dataMap["pattern"] = pattern;
    }
    if (subCategory != null) {
      dataMap["sub_category"] = subCategory;
    }

    final formData = FormData.fromMap(dataMap);

    try {
      final response = await dio.post(
        ApiConstants.uploadFashion,
        data: formData,
      );

      final responseData = response.data;
      debugPrint('[API] Upload response: $responseData');

      if (responseData == null) {
        throw Exception('Upload gagal: server tidak mengembalikan data');
      }

      final status = responseData['status'];
      if (status == false) {
        final msg = responseData['message'] ?? 'Upload gambar gagal';
        throw Exception(msg);
      }

      final data = responseData['data'];
      if (data == null) {
        throw Exception('Upload gagal: response data null');
      }

      final idItem = data['id_item'];
      if (idItem == null) {
        throw Exception('Upload gagal: id_item tidak ada di response');
      }

      debugPrint('[API] Upload berhasil, id_item=$idItem');
      return idItem as int;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'];

      debugPrint('[API] Upload DioException: $statusCode $message');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Upload gambar timeout. Server tidak merespons dalam 5 menit.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Tidak dapat terhubung ke server. Pastikan backend berjalan di http://10.0.2.2:5000');
      }
      if (statusCode == 400) {
        throw Exception(message ?? 'Format gambar tidak valid');
      }
      if (statusCode == 413) {
        throw Exception('Ukuran gambar terlalu besar (maks 16MB)');
      }
      throw Exception(message ?? 'Upload gambar gagal (HTTP $statusCode)');
    }
  }

  Future<List<Map<String, dynamic>>> getFashionItems() async {
    final response = await dio.get(ApiConstants.fashionItems);
    return List<Map<String, dynamic>>.from(response.data["data"]);
  }

  Future<List<Map<String, dynamic>>> getFashionByCategory(
    int categoryId,
  ) async {
    final response = await dio.get(
      "${ApiConstants.fashionByCategory}/$categoryId",
    );
    return List<Map<String, dynamic>>.from(response.data["data"]);
  }

  /// Ambil random dataset items untuk InspirationGrid di HomePage.
  Future<List<Map<String, dynamic>>> getInspirations({int limit = 12}) async {
    try {
      final response = await dio.get(
        ApiConstants.fashionInspirations,
        queryParameters: {"limit": limit},
      );
      return List<Map<String, dynamic>>.from(response.data["data"]);
    } on DioException catch (e) {
      debugPrint('[API] getInspirations error: ${e.type}');
      return [];
    }
  }

  // OUTFIT

  Future<Map<String, dynamic>> generateOutfit(int itemId) async {
    debugPrint('[API] generateOutfit untuk item_id=$itemId');

    try {
      final response = await dio.get(
        "${ApiConstants.generateOutfit}/$itemId",
      );

      final responseData = response.data;
      debugPrint(
          '[API] generateOutfit response keys: ${responseData?.keys?.toList()}');

      if (responseData == null) {
        throw Exception('Server tidak mengembalikan data rekomendasi');
      }

      final status = responseData['status'];
      if (status == false) {
        final msg = responseData['message'] ?? 'Generate rekomendasi gagal';
        debugPrint('[API] generateOutfit status=false: $msg');
        throw Exception(msg);
      }

      final outfit = responseData['outfit'];
      if (outfit == null) {
        debugPrint('[API] generateOutfit: key "outfit" tidak ada di response');
        throw Exception(
            'Data outfit tidak ditemukan dalam response. Periksa backend.');
      }

      if (outfit['uploaded_item'] == null) {
        debugPrint('[API] generateOutfit: uploaded_item null');
        throw Exception('Data outfit tidak lengkap: uploaded_item tidak ada');
      }

      debugPrint(
          '[API] generateOutfit berhasil. Keys: ${outfit.keys.toList()}');
      return Map<String, dynamic>.from(outfit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'];

      debugPrint(
          '[API] generateOutfit DioException: type=${e.type} status=$statusCode msg=$message');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Timeout saat generate rekomendasi. ResNet50 butuh waktu, coba lagi.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Server tidak merespons. Pastikan backend berjalan di http://10.0.2.2:5000');
      }
      if (statusCode == 400) {
        throw Exception(message ?? 'Item tidak valid untuk generate outfit');
      }
      if (statusCode == 404) {
        throw Exception('Item tidak ditemukan di server');
      }
      if (statusCode == 500) {
        throw Exception(message ??
            'Server error saat generate outfit. Periksa log backend.');
      }
      throw Exception(message ?? 'Generate outfit gagal (HTTP $statusCode)');
    }
  }

  //  FAVORITE

  Future<bool> addFavorite(int userId, int itemId) async {
    try {
      await dio.post(
        ApiConstants.favorite,
        data: {
          "user_id": userId,
          "item_id": itemId,
        },
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return false;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
    final response = await dio.get(
      "${ApiConstants.favorite}/$userId",
    );
    return List<Map<String, dynamic>>.from(response.data["data"]);
  }

  Future<bool> deleteFavorite(int userId, int itemId) async {
    try {
      await dio.delete(
        ApiConstants.favorite,
        data: {
          "user_id": userId,
          "item_id": itemId,
        },
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }
      rethrow;
    }
  }

  // AUTH EXTRAS

  /// Kirim ulang email verifikasi ke email yang terdaftar.
  /// Returns true jika berhasil, false jika email tidak terdaftar atau sudah terverifikasi.
  Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      final response = await dio.post(
        ApiConstants.resendVerification,
        data: {"email": email},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Gagal mengirim email verifikasi';
      return {"status": false, "message": message};
    }
  }

  // CATEGORIES

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await dio.get("${ApiConstants.categories}/");
    return List<Map<String, dynamic>>.from(response.data["data"]);
  }

  // COLORS

  Future<List<Map<String, dynamic>>> getColors() async {
    final response = await dio.get("${ApiConstants.colors}/");
    return List<Map<String, dynamic>>.from(response.data["data"]);
  }
}
