import '../models/availability.dart';
import '../models/booking.dart';
import '../models/conversation.dart';
import '../models/mentor.dart';
import '../models/mentor_earnings.dart';
import '../models/message.dart';
import '../models/review.dart';
import '../models/time_slot.dart';

const _seedMentors = [
  Mentor(
    id: '1',
    name: 'Dr. Sarah Chen',
    title: 'Senior Flutter Engineer',
    company: 'Google',
    expertise: ['Flutter', 'Dart', 'Firebase', 'GraphQL'],
    ratePerSlot: 25,
    rating: 4.9,
    reviewCount: 128,
    totalSessions: 147,
    yearsExperience: 8,
    repeatRate: 96,
    verified: true,
    bio:
        'Sarah helps mobile engineers master Flutter architecture, scalable state management, and production-ready app delivery.',
    avatarInitials: 'SC',
    avatarColorValue: 0xFF00C9FF,
  ),
  Mentor(
    id: '2',
    name: 'Marcus Kim',
    title: 'iOS Architect',
    company: 'Apple',
    expertise: ['Swift', 'SwiftUI', 'UIKit'],
    ratePerSlot: 35,
    rating: 5,
    reviewCount: 96,
    totalSessions: 89,
    yearsExperience: 12,
    repeatRate: 94,
    verified: true,
    bio:
        'Marcus mentors developers on iOS architecture, app performance, SwiftUI, and App Store launch readiness.',
    avatarInitials: 'MK',
    avatarColorValue: 0xFFF5C842,
  ),
  Mentor(
    id: '3',
    name: 'Priya Raj',
    title: 'ML Engineer',
    company: 'Meta',
    expertise: ['Python', 'TensorFlow', 'PyTorch'],
    ratePerSlot: 30,
    rating: 4.80,
    reviewCount: 174,
    totalSessions: 203,
    yearsExperience: 6,
    repeatRate: 91,
    verified: false,
    bio:
        'Priya helps founders and engineers understand practical machine learning, model selection, and AI product strategy.',
    avatarInitials: 'PR',
    avatarColorValue: 0xFF00E5A0,
  ),
  Mentor(
    id: '4',
    name: 'James Adkins',
    title: 'Founder & CEO',
    company: 'YC W22',
    expertise: ['Startups', 'Fundraising', 'Product'],
    ratePerSlot: 45,
    rating: 4.9,
    reviewCount: 64,
    totalSessions: 56,
    yearsExperience: 10,
    repeatRate: 89,
    verified: true,
    bio:
        'James advises early-stage founders on fundraising, MVP strategy, product positioning, and investor storytelling.',
    avatarInitials: 'JA',
    avatarColorValue: 0xFF8B5CF6,
  ),
  Mentor(
    id: '5',
    name: 'Lena Torres',
    title: 'Head of Design',
    company: 'Figma',
    expertise: ['UI/UX', 'Design Systems', 'Figma'],
    ratePerSlot: 28,
    rating: 4.7,
    reviewCount: 142,
    totalSessions: 112,
    yearsExperience: 9,
    repeatRate: 93,
    verified: true,
    bio:
        'Lena mentors designers and founders on clean product UX, design systems, usability, and visual polish.',
    avatarInitials: 'LT',
    avatarColorValue: 0xFFFF6B9D,
  ),
  Mentor(
    id: '6',
    name: 'Omar Hassan',
    title: 'Backend Architect',
    company: 'Stripe',
    expertise: ['Python', 'Django', 'PostgreSQL', 'GraphQL'],
    ratePerSlot: 40,
    rating: 4.8,
    reviewCount: 87,
    totalSessions: 78,
    yearsExperience: 11,
    repeatRate: 90,
    verified: true,
    bio:
        'Omar helps developers design scalable backend systems, payment infrastructure, APIs, and production databases.',
    avatarInitials: 'OH',
    avatarColorValue: 0xFF22D3EE,
  ),
];

final mockMentors = List<Mentor>.generate(30, (index) {
  final base = _seedMentors[index % _seedMentors.length];
  final id = '${index + 1}';
  if (index < _seedMentors.length) return base;
  final tracks = ['Career', 'Android', 'AI/ML', 'Design', 'Backend', 'Startup'];
  return Mentor(
    id: id,
    name: '${base.name.split(' ').first} ${tracks[index % tracks.length]}',
    title: '${base.title} Mentor',
    company: ['Google', 'Apple', 'Meta', 'Stripe', 'Figma'][index % 5],
    expertise: [...base.expertise.take(2), tracks[index % tracks.length]],
    ratePerSlot: base.ratePerSlot + (index % 5) * 3,
    rating: double.parse((4.6 + (index % 5) / 10).toStringAsFixed(1)),
    reviewCount: base.reviewCount + index,
    totalSessions: base.totalSessions + index * 3,
    yearsExperience: base.yearsExperience + index % 4,
    repeatRate: 86 + index % 12,
    verified: index.isEven,
    bio: base.bio,
    avatarInitials: base.avatarInitials,
    avatarColorValue: base.avatarColorValue,
  );
});

final mockUpcomingBooking = Booking(
  id: 'booking-1',
  mentorId: '1',
  mentor: mockMentors.first,
  scheduledAt: DateTime.now().add(const Duration(hours: 3)),
  durationMinutes: 15,
  status: 'confirmed',
  amount: 25,
  agoraChannel: 'micro_mentor_demo_channel',
  sessionGoal: 'Review Flutter architecture choices.',
);

final mockConversations = [
  Conversation(
    id: 'c1',
    participantName: 'Dr. Sarah Chen',
    participantInitials: 'SC',
    lastMessage: 'Bring your Riverpod questions.',
    lastMessageAt: DateTime.now().subtract(const Duration(minutes: 12)),
    unreadCount: 2,
    isOnline: true,
    avatarColorValue: 0xFF00C9FF,
  ),
  Conversation(
    id: 'c2',
    participantName: 'Marcus Kim',
    participantInitials: 'MK',
    lastMessage: 'I shared a launch checklist.',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
    unreadCount: 0,
    isOnline: false,
    avatarColorValue: 0xFFF5C842,
  ),
  Conversation(
    id: 'c3',
    participantName: 'Lena Torres',
    participantInitials: 'LT',
    lastMessage: 'Your design system is close.',
    lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
    unreadCount: 1,
    isOnline: true,
    avatarColorValue: 0xFFFF6B9D,
  ),
];

final mockMessages = [
  Message(
    id: 'm1',
    conversationId: 'c1',
    senderId: 'mentor',
    text: 'What would make the session a win for you?',
    sentAt: DateTime.now().subtract(const Duration(minutes: 20)),
    isMine: false,
    type: 'text',
  ),
  Message(
    id: 'm2',
    conversationId: 'c1',
    senderId: 'me',
    text: 'I want feedback on state management and routing.',
    sentAt: DateTime.now().subtract(const Duration(minutes: 16)),
    isMine: true,
    type: 'text',
  ),
  Message(
    id: 'm3',
    conversationId: 'c1',
    senderId: 'mentor',
    text: 'Perfect. Bring the app map and one tough screen.',
    sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
    isMine: false,
    type: 'file',
    attachmentName: 'session-prep.pdf',
  ),
];

final mockReviews = [
  Review(
    id: 'r1',
    mentorId: '1',
    userName: 'Alex Morgan',
    rating: 5,
    comment: 'Sharp, practical guidance that saved me days.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    tags: ['Helpful', 'Clear'],
  ),
  Review(
    id: 'r2',
    mentorId: '1',
    userName: 'Nina Patel',
    rating: 5,
    comment: 'Excellent architecture advice with clear tradeoffs.',
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
    tags: ['Knowledgeable'],
  ),
  Review(
    id: 'r3',
    mentorId: '2',
    userName: 'Theo James',
    rating: 4,
    comment: 'Great iOS launch feedback.',
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
    tags: ['Friendly'],
  ),
];

const mockEarnings = MentorEarnings(
  thisMonth: 2480,
  sessionsCount: 42,
  avgRating: 4.9,
  repeatClientPct: 92,
);

final mockTodaySessions = [
  mockUpcomingBooking,
  Booking(
    id: 'booking-2',
    mentorId: '5',
    mentor: mockMentors[4],
    scheduledAt: DateTime.now().add(const Duration(hours: 5)),
    durationMinutes: 30,
    status: 'confirmed',
    amount: 56,
    agoraChannel: 'micro_mentor_demo_channel',
    sessionGoal: 'Improve onboarding UX.',
  ),
];

final mockWeeklyAvailability = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    .map(
      (day) => Availability(
        id: 'a-$day',
        mentorId: 'mentor-1',
        day: day,
        isEnabled: day != 'Sun',
        slots: [
          TimeSlot(
            id: '$day-1',
            startTime: '09:00',
            endTime: '09:15',
            isBooked: day == 'Mon',
          ),
          TimeSlot(
            id: '$day-2',
            startTime: '10:00',
            endTime: '10:15',
            isBooked: false,
          ),
          TimeSlot(
            id: '$day-3',
            startTime: '14:00',
            endTime: '14:15',
            isBooked: day == 'Wed',
          ),
        ],
      ),
    )
    .toList();
