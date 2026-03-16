class AppConstants {
  AppConstants._();

  static const String appName = 'Handymenskills';

  // Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mwlazxvlybqrlwbfxxny.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_G5UDOVh1AZ3wjY_FGhhQ0Q_ujWlJdo5',
  );

  // Paystack
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_d64ed1a2ec6e04441b4627b6ae431dd99879aa1a',
  );
  static const String paystackSecretKey = String.fromEnvironment(
    'PAYSTACK_SECRET_KEY',
    defaultValue: 'sk_test_d2e935c587ac4f7c509960a18d21bef725eaa0db',
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
