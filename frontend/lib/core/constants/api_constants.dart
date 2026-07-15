class ApiConstants {
  static const String baseUrl = "http://10.0.2.2:5000";
  static const String apiUrl = "$baseUrl/api";

  // Auth
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String resendVerification = "/auth/resend-verification";

  // Fashion
  static const String uploadFashion = "/fashion/upload";
  static const String fashionItems = "/fashion";
  static const String fashionByCategory = "/fashion/category";
  static const String fashionInspirations = "/fashion/inspirations";

  // Outfit
  static const String generateOutfit = "/outfit/generate";

  // Recommendation
  static const String recommendation = "/recommendation/item";

  // Favorite
  static const String favorite = "/favorite";

  // Categories
  static const String categories = "/categories";

  // Colors
  static const String colors = "/colors";

  // Images
  static const String images = "/images";

  static String imageUrl(String relativePath) {
    if (relativePath.startsWith("http")) {
      return relativePath;
    }
    return "$baseUrl$relativePath";
  }
}
