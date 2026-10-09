import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tripbybid/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tripbybid/features/auth/domain/entities/user.dart';
import 'package:tripbybid/features/auth/domain/repositories/auth_repository.dart';
import 'package:tripbybid/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/login_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/logout_usecase.dart';

export 'mocks.mocks.dart';

/// Mockito cannot invent values of the sealed [Result] type; call this in
/// `setUpAll` of any test that stubs a method returning one.
@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<AuthRemoteDataSource>(),
  MockSpec<AuthLocalDataSource>(),
  MockSpec<LoginUseCase>(),
  MockSpec<GetCurrentUserUseCase>(),
  MockSpec<LogoutUseCase>(),
])
void provideResultDummies() {
  provideDummy<Result<User>>(const Err(ServerFailure('dummy')));
  provideDummy<Result<User?>>(const Err(ServerFailure('dummy')));
  provideDummy<Result<void>>(const Err(ServerFailure('dummy')));
}
