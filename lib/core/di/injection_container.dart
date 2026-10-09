import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecases.dart';
import '../../features/auth/domain/usecases/watch_session_ended_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/login_cubit.dart';
import '../../features/auth/presentation/bloc/signup_cubit.dart';
import '../../features/auth/presentation/bloc/verify_email_cubit.dart';
import '../../features/chat/data/datasources/chat_remote_data_source.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/chat_usecases.dart';
import '../../features/chat/presentation/bloc/chat_cubit.dart';
import '../../features/chat/presentation/bloc/inbox_cubit.dart';
import '../../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/notification_usecases.dart';
import '../../features/notifications/presentation/bloc/notifications_cubit.dart';
import '../../features/onboarding/data/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/mark_intro_seen_usecase.dart';
import '../../features/onboarding/domain/onboarding_repository.dart';
import '../../features/onboarding/presentation/bloc/intro_cubit.dart';
import '../../features/payments/data/datasources/payments_remote_data_source.dart';
import '../../features/payments/data/gateways/cashfree_payment_gateway.dart';
import '../../features/payments/data/repositories/payments_repository_impl.dart';
import '../../features/payments/domain/repositories/payments_repository.dart';
import '../../features/payments/domain/usecases/payment_usecases.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecases.dart';
import '../../features/profile/presentation/bloc/edit_profile_cubit.dart';
import '../../features/profile/presentation/bloc/notification_settings_cubit.dart';
import '../../features/profile/presentation/bloc/payment_history_cubit.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';
import '../../features/trips/data/datasources/trips_remote_data_source.dart';
import '../../features/trips/data/datasources/places_local_data_source.dart';
import '../../features/trips/data/repositories/places_repository_impl.dart';
import '../../features/trips/data/repositories/trips_repository_impl.dart';
import '../../features/trips/domain/repositories/places_repository.dart';
import '../../features/trips/domain/repositories/trips_repository.dart';
import '../../features/trips/domain/usecases/get_active_bids_usecase.dart';
import '../../features/trips/domain/usecases/post_trip_request.dart';
import '../../features/trips/domain/usecases/search_places.dart';
import '../../features/trips/domain/usecases/trip_actions.dart';
import '../../features/trips/domain/usecases/trip_queries.dart';
import '../../features/trips/presentation/detail/trip_detail_cubit.dart';
import '../../features/trips/presentation/home/home_cubit.dart';
import '../../features/trips/presentation/list/trips_list_cubit.dart';
import '../../features/trips/presentation/new_request/new_request_cubit.dart';
import '../../features/trips/presentation/new_request/place_search_cubit.dart';
import '../config/app_config.dart';
import '../network/access_token_provider.dart';
import '../network/api_client.dart';
import '../network/supabase_token_provider.dart';

/// The service locator. Only this file, `main.dart`, `app.dart` and pages
/// (inside `BlocProvider.create`) may use it.
final sl = GetIt.instance;

/// Registers everything. [supabase] and [prefs] are initialised in `main`.
void configureDependencies({
  required SupabaseClient supabase,
  required SharedPreferences prefs,
  required FlutterSecureStorage secureStorage,
}) {
  sl
    // External
    ..registerLazySingleton<http.Client>(http.Client.new)
    ..registerSingleton<FlutterSecureStorage>(secureStorage)
    ..registerSingleton<GoTrueClient>(supabase.auth)
    // Core
    ..registerLazySingleton<AccessTokenProvider>(
      () => SupabaseTokenProvider(sl()),
    )
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(
        httpClient: sl(),
        tokens: sl(),
        baseUrl: AppConfig.apiBaseUrl,
      ),
    )
    ..registerSingleton<OnboardingRepository>(OnboardingRepositoryImpl(prefs))
    ..registerLazySingleton(() => MarkIntroSeenUseCase(sl()))
    ..registerFactory(() => IntroCubit(markIntroSeen: sl()));

  _registerAuth();
  _registerTrips();
  _registerPayments();
  _registerChat();
  _registerNotifications();
  _registerProfile();
}

void _registerAuth() {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(auth: sl(), api: sl()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remote: sl(), local: sl()),
    )
    ..registerLazySingleton(() => LoginUseCase(sl()))
    ..registerLazySingleton(() => SignUpUseCase(sl()))
    ..registerLazySingleton(() => VerifyEmailUseCase(sl()))
    ..registerLazySingleton(() => ResendCodeUseCase(sl()))
    ..registerLazySingleton(() => GetCurrentUserUseCase(sl()))
    ..registerLazySingleton(() => LogoutUseCase(sl()))
    ..registerLazySingleton(() => WatchSessionEndedUseCase(sl()))
    ..registerFactory(
      () =>
          AuthBloc(getCurrentUser: sl(), logout: sl(), watchSessionEnded: sl()),
    )
    ..registerFactory(() => LoginCubit(login: sl(), resendCode: sl()))
    ..registerFactory(() => SignupCubit(signUp: sl(), getCurrentUser: sl()))
    ..registerFactory(
      () => VerifyEmailCubit(verifyEmail: sl(), resendCode: sl()),
    );
}

void _registerTrips() {
  sl
    ..registerLazySingleton<TripsRemoteDataSource>(
      () => TripsRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<TripsRepository>(() => TripsRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetMyTripsUseCase(sl()))
    ..registerLazySingleton(() => GetTripDetailUseCase(sl()))
    ..registerLazySingleton(() => PostTripRequestUseCase(sl()))
    ..registerLazySingleton(() => UpdateTripUseCase(sl()))
    ..registerLazySingleton(() => CancelTripUseCase(sl()))
    ..registerLazySingleton(() => AcceptBidUseCase(sl()))
    ..registerLazySingleton(() => ReleaseBidUseCase(sl()))
    ..registerLazySingleton(() => GetCancellationQuoteUseCase(sl()))
    ..registerLazySingleton(() => CancelBookingUseCase(sl()))
    ..registerLazySingleton(() => VerifyTicketUseCase(sl()))
    ..registerLazySingleton(() => RequestCorrectionUseCase(sl()))
    ..registerLazySingleton(() => RaiseSupportTicketUseCase(sl()))
    ..registerLazySingleton(() => RateAgentUseCase(sl()))
    ..registerLazySingleton(() => GetActiveBidsUseCase(sl()))
    ..registerFactory(
      () => HomeCubit(
        getMyTrips: sl(),
        getActiveBids: sl(),
        getUnreadCount: sl(),
      ),
    )
    ..registerFactory(() => TripsListCubit(getMyTrips: sl()))
    ..registerLazySingleton<PlacesLocalDataSource>(
      PlacesLocalDataSourceImpl.new,
    )
    ..registerLazySingleton<PlacesRepository>(() => PlacesRepositoryImpl(sl()))
    ..registerLazySingleton(() => SearchPlacesUseCase(sl()))
    ..registerFactory(() => NewRequestCubit(postTrip: sl()))
    ..registerFactory(() => PlaceSearchCubit(searchPlaces: sl()))
    ..registerFactory(
      () => TripDetailCubit(
        getTripDetail: sl(),
        getPaymentSummary: sl(),
        payForBid: sl(),
        acceptBid: sl(),
        releaseBid: sl(),
        cancelTrip: sl(),
        updateTrip: sl(),
        getCancellationQuote: sl(),
        cancelBooking: sl(),
        verifyTicket: sl(),
        requestCorrection: sl(),
        raiseSupportTicket: sl(),
        rateAgent: sl(),
      ),
    );
}

void _registerPayments() {
  sl
    ..registerLazySingleton<PaymentsRemoteDataSource>(
      () => PaymentsRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<PaymentsRepository>(
      () => PaymentsRepositoryImpl(sl()),
    )
    ..registerLazySingleton<PaymentGateway>(
      () => CashfreePaymentGateway(
        production: AppConfig.cashfreeEnv == 'production',
      ),
    )
    ..registerLazySingleton(() => GetPaymentSummaryUseCase(sl()))
    ..registerLazySingleton(() => GetPaymentHistoryUseCase(sl()))
    ..registerLazySingleton(() => PayForBidUseCase(sl(), sl()));
}

void _registerChat() {
  sl
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(
        sl(),
        currentUserId: () => sl<GoTrueClient>().currentUser?.id,
      ),
    )
    ..registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetConversationsUseCase(sl()))
    ..registerLazySingleton(() => GetMessagesUseCase(sl()))
    ..registerLazySingleton(() => SendMessageUseCase(sl()))
    ..registerLazySingleton(() => MarkConversationReadUseCase(sl()))
    ..registerFactory(() => InboxCubit(getConversations: sl()))
    ..registerFactory(
      () => ChatCubit(
        getConversations: sl(),
        getMessages: sl(),
        sendMessage: sl(),
        markRead: sl(),
      ),
    );
}

void _registerNotifications() {
  sl
    ..registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetNotificationsUseCase(sl()))
    ..registerLazySingleton(() => GetUnreadCountUseCase(sl()))
    ..registerLazySingleton(() => MarkNotificationReadUseCase(sl()))
    ..registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()))
    ..registerFactory(
      () => NotificationsCubit(
        getNotifications: sl(),
        markRead: sl(),
        markAllRead: sl(),
        getMyTrips: sl(),
      ),
    );
}

void _registerProfile() {
  sl
    ..registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetProfileUseCase(sl()))
    ..registerLazySingleton(() => UpdateProfileUseCase(sl()))
    ..registerLazySingleton(() => GetNotificationPreferencesUseCase(sl()))
    ..registerLazySingleton(() => UpdateNotificationPreferencesUseCase(sl()))
    ..registerFactory(() => ProfileCubit(getProfile: sl(), getMyTrips: sl()))
    ..registerFactory(
      () => EditProfileCubit(getProfile: sl(), updateProfile: sl()),
    )
    ..registerFactory(
      () => NotificationSettingsCubit(
        getPreferences: sl(),
        updatePreferences: sl(),
      ),
    )
    ..registerFactory(() => PaymentHistoryCubit(getHistory: sl()));
}
