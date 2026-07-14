import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aina/core/config/env.dart';
import 'package:aina/core/constants/api_constants.dart';

/// Attaches the current Supabase session's access token (and the anon
/// API key, which Supabase's REST/Storage endpoints require on every
/// request) to outgoing requests made through this app's own [DioClient]
/// — i.e. calls to custom Edge Functions or REST endpoints outside the
/// `supabase_flutter` SDK's own (already-authenticated) client.
///
/// Requests made before a session exists still go through with just the
/// anon key, which is correct for public reads under RLS.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = _supabaseClient.auth.currentSession;

    options.headers[ApiConstants.headerApiKey] = Env.supabaseAnonKey;

    if (session != null) {
      options.headers[ApiConstants.headerAuthorization] = 'Bearer ${session.accessToken}';
    } else {
      options.headers[ApiConstants.headerAuthorization] = 'Bearer ${Env.supabaseAnonKey}';
    }

    handler.next(options);
  }
}
