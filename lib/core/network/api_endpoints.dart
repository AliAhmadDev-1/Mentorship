class ApiEndpoints {
  const ApiEndpoints._();

  //   static const defaultBaseUrl = String.fromEnvironment(
  //     'API_BASE_URL',
  //     defaultValue: 'https://192.168.1.29:8000/api',
  //   );

  // static const defaultBaseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue:
  //       'http://micro-mentor-alb-869670005.us-east-1.elb.amazonaws.com/api',
  // );
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://micro-mentor-backend.onrender.com/api',
  );
  static const register = '/auth/register/';

  static const login = '/auth/login/';

  static const tokenRefresh = '/auth/token/refresh/';

  static const logout = '/auth/logout/';

  static const home = '/home/';

  static const health = '/health/';

  static const mentors = '/mentors/';

  static String mentorDetail(Object mentorId) => '/mentors/$mentorId/';

  static String mentorAvailability(Object mentorId) =>
      '/mentors/$mentorId/availability/';

  static const bookings = '/bookings/';

  static const sessions = '/sessions/';

  static String sessionDetail(Object sessionId) => '/sessions/$sessionId/';

  static String confirmPayment(Object sessionId) =>
      '/sessions/$sessionId/payment/confirm/';

  static String completeSession(Object sessionId) =>
      '/sessions/$sessionId/complete/';

  static String cancelSession(Object sessionId) =>
      '/sessions/$sessionId/cancel/';

  static String submitSessionReview(Object sessionId) =>
      '/sessions/$sessionId/review/';

  static String paymentStatus(Object sessionId) => '/payments/$sessionId/';

  static const profile = '/profile/';

  static const mentorDashboard = '/mentor-dashboard/';

  static const mentorOnboarding = '/mentor-onboarding/';

  static const mentorOnboardingStatus = '/mentor-onboarding/status/';

  static const mentorOnboardingSubmit = '/mentor-onboarding/submit/';

  static const mentorDocumentUploadRequest =
      '/mentor-onboarding/documents/upload-request/';

  static String mentorDocumentConfirm(Object documentId) =>
      '/mentor-onboarding/documents/$documentId/confirm/';

  static String mentorDocument(Object documentId) =>
      '/mentor-onboarding/documents/$documentId/';

  static const categories = '/categories/';

  static String category(Object categoryId) => '/categories/$categoryId/';

  static const expertise = '/expertise/';

  static String expertiseDetail(Object expertiseId) =>
      '/expertise/$expertiseId/';

  static const mentorProfiles = '/mentor-profiles/';

  static String mentorProfile(Object mentorId) => '/mentor-profiles/$mentorId/';

  static const packages = '/packages/';

  static String packageDetail(Object packageId) => '/packages/$packageId/';

  static const availabilityWindows = '/availability-windows/';

  static String availabilityWindow(Object windowId) =>
      '/availability-windows/$windowId/';

  static const reviews = '/reviews/';

  static String review(Object reviewId) => '/reviews/$reviewId/';

  static const conversations = '/conversations/';

  static String conversation(Object conversationId) =>
      '/conversations/$conversationId/';

  static String conversationMessages(Object conversationId) =>
      '/conversations/$conversationId/messages/';
}
