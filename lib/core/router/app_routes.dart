/// Route paths. Features navigate with these (via `context.go/push`) and
/// never import each other's pages.
abstract final class AppRoutes {
  // Signed-out flow.
  static const splash = '/splash';
  static const intro = '/intro';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';

  /// Routes reachable without a session.
  static const public = {splash, intro, welcome, login, signup, verifyEmail};

  // Tabs.
  static const home = '/home';
  static const trips = '/trips';
  static const inbox = '/inbox';
  static const profile = '/profile';

  // Full-screen pages over the tabs.
  static const newRequest = '/new-request';
  static const notifications = '/notifications';
  static const editProfile = '/profile/edit';
  static const notificationSettings = '/profile/notifications';
  static const paymentHistory = '/profile/payments';
  static const help = '/help';

  static String verifyEmailFor(String email) =>
      '$verifyEmail?email=${Uri.encodeQueryComponent(email)}';

  /// [type] is `flight`, `train` or `hotel`.
  static String newRequestOf(String type) => '$newRequest?type=$type';

  /// The booking detail of a request. [tab] is `overview`, `bids`,
  /// `timeline` or `docs`.
  static String trip(String requestId, {String? tab}) =>
      '/trip/$requestId${tab == null ? '' : '?tab=$tab'}';

  static String chat(String bookingId) => '/chat/$bookingId';
}
