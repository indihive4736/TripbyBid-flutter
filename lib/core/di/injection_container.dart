import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/login_cubit.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/token_storage.dart';

/// The service locator. Only this file, `main.dart`, the router and pages
/// (inside `BlocProvider.create`) may use it.
final sl = GetIt.instance;

void configureDependencies() {
  // External
  sl
    ..registerLazySingleton<http.Client>(http.Client.new)
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    )
    // Core
    ..registerLazySingleton<TokenStorage>(() => SecureTokenStorage(sl()))
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(
        httpClient: sl(),
        tokenStorage: sl(),
        baseUrl: AppConfig.apiBaseUrl,
      ),
    );

  _registerAuth();
}

void _registerAuth() {
  sl
    // Data sources
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(tokenStorage: sl(), secureStorage: sl()),
    )
    // Repository
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remote: sl(), local: sl()),
    )
    // Use cases
    ..registerLazySingleton(() => LoginUseCase(sl()))
    ..registerLazySingleton(() => GetCurrentUserUseCase(sl()))
    ..registerLazySingleton(() => LogoutUseCase(sl()))
    // Presentation
    ..registerFactory(() => AuthBloc(getCurrentUser: sl(), logout: sl()))
    ..registerFactory(() => LoginCubit(login: sl()));
}
