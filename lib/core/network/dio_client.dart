import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aina/core/config/app_config.dart';
import 'package:aina/core/config/env.dart';
import 'package:aina/core/network/interceptors/auth_interceptor.dart';
import 'package:aina/core/network/interceptors/logging_interceptor.dart';
import 'package:aina/core/network/interceptors/retry_interceptor.dart';
import 'package:aina/core/network/network_info.dart';

/// Factory for a fully configured [Dio] instance.
///
/// This client is used for calls that go *outside* the `supabase_flutter`
/// SDK's own client — primarily custom Edge Functions and any future
/// third-party REST integrations (payment gateways, OneSignal, etc.).
/// Direct table reads/writes should go through `Supabase.instance.client`
/// (see [SupabaseService]) so they benefit from the SDK's built-in
/// Postgrest/Realtime/Storage handling.
class DioClient {
  DioClient(this._supabaseClient, this._networkInfo);

  final SupabaseClient _supabaseClient;
  final NetworkInfo _networkInfo;

  Dio build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.supabaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(_supabaseClient),
      RetryInterceptor(dio, _networkInfo),
      LoggingInterceptor(),
    ]);

    return dio;
  }
}
