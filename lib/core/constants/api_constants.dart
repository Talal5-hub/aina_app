/// Constants used by the networking layer: query parameter names, header
/// keys, and Supabase RPC parameter names. Kept separate from
/// [AppConstants] because these are network-protocol concerns, not
/// app-storage concerns.
class ApiConstants {
  const ApiConstants._();

  // Common query parameter keys
  static const String paramPage = 'page';
  static const String paramPageSize = 'page_size';
  static const String paramSortBy = 'sort_by';
  static const String paramCityId = 'city_id';
  static const String paramCategoryId = 'category_id';
  static const String paramSearchQuery = 'q';

  // nearby_salons RPC parameter names (must match the Postgres function
  // signature defined in supabase/migrations/0005_functions_and_triggers.sql)
  static const String rpcParamLat = 'lat';
  static const String rpcParamLng = 'lng';
  static const String rpcParamRadiusKm = 'radius_km';
  static const String rpcParamResultLimit = 'result_limit';

  // Headers
  static const String headerAuthorization = 'Authorization';
  static const String headerApiKey = 'apikey';
  static const String headerContentType = 'Content-Type';
  static const String contentTypeJson = 'application/json';
}
