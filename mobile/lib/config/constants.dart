class AppConstants {
  AppConstants._();

  static const String appName = 'Artisan Marketplace';

  // Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // Paystack
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_xxx',
  );

  // Google Maps
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String portfolioBucket = 'portfolio';
  static const String jobImagesBucket = 'job-images';
  static const String idDocumentsBucket = 'id-documents';
  static const String chatAttachmentsBucket = 'chat-attachments';
  static const String completionPhotosBucket = 'completion-photos';

  // Business rules
  static const double commissionRate = 0.15;
  static const int gracePeriodDays = 3;
  static const int maxStrikes = 3;
  static const int jobExpiryDays = 30;
  static const double minBudget = 500;
  static const double minWithdrawal = 5000;
  static const int reviewWindowDays = 7;
  static const int maxPortfolioImages = 10;
  static const int maxActiveApplications = 10;

  // Pagination
  static const int defaultPageSize = 20;

  // Currency
  static const String currency = 'NGN';
  static const String currencySymbol = '₦';

  // Phone
  static const String countryCode = '+234';
}
