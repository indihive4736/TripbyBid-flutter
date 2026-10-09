/// Traveler FAQs, from the web client's `lib/help/faq.ts`. Answers that
/// point at web screens ("Settings › Billing") name the app's screens.
final class FaqEntry {
  const FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

final class FaqTopic {
  const FaqTopic(this.label, this.entries);

  final String label;
  final List<FaqEntry> entries;
}

const supportEmail = 'support@tripbybid.com';

const faqTopics = [
  FaqTopic('Bookings & bids', [
    FaqEntry(
      'How does bidding work on TripByBid?',
      'Post one request with your route, dates and budget. Verified travel '
          'agents send offers with a total price and their cancellation '
          'terms. You compare the offers and pay for the one you choose — '
          'nothing is charged until you pay for a bid.',
    ),
    FaqEntry(
      'How long until I receive bids?',
      'Agents see your request as soon as you post it. How quickly offers '
          'arrive depends on the route and dates; you get a notification for '
          'each new bid, and every bid appears on the request’s page.',
    ),
    FaqEntry(
      'Can I edit a request after posting it?',
      'You can change a request until the first bid arrives. After that it '
          'is locked, so every agent bids on the same trip. If something '
          'important changed, email support with the request ID.',
    ),
  ]),
  FaqTopic('Payments & refunds', [
    FaqEntry(
      'Is my payment secure?',
      'Payments are processed by Cashfree, a regulated payment gateway; '
          'TripByBid never sees your card details. Always pay on TripByBid — '
          'never send money to an agent directly.',
    ),
    FaqEntry(
      'When will I get my refund?',
      'When a booking is cancelled, the refund shown in the cancellation '
          'quote goes back to your original payment method. Your bank may '
          'take a few working days to show it.',
    ),
    FaqEntry(
      'Where are my payment receipts?',
      'Go to Profile › Payments & receipts. Every payment is listed there '
          'with its trip and receipt number.',
    ),
  ]),
  FaqTopic('Cancellations & changes', [
    FaqEntry(
      'How do I cancel a booking?',
      'Open the booking and choose Cancel booking. Before you confirm, you '
          'see exactly how much you get back — it depends on the agent’s '
          'cancellation terms and how close the trip is. The platform fee is '
          'not refunded when you cancel.',
    ),
    FaqEntry(
      'Can I change my travel date?',
      'Message your agent in the booking’s chat. Whether a date can change, '
          'and what it costs, depends on the airline, railway or hotel rules '
          '— the agent will tell you before anything changes.',
    ),
  ]),
  FaqTopic('Account & security', [
    FaqEntry(
      'How do I update my profile?',
      'Go to Profile › Personal details to change your name, phone number '
          'and bio.',
    ),
    FaqEntry(
      'How do I choose which notifications I get?',
      'Go to Profile › Notifications and switch email and push alerts on or '
          'off for bids, messages and booking updates.',
    ),
  ]),
  FaqTopic('Agents & trust', [
    FaqEntry(
      'How are agents verified?',
      'Agents send their business documents to TripByBid, and our team '
          'reviews them before marking the agency as verified. Verified '
          'agents show a check mark next to their name.',
    ),
    FaqEntry(
      'What if my agent stops responding?',
      'Message them in the booking’s chat first. If you still hear nothing, '
          'email support with your booking ID and we will step in.',
    ),
  ]),
  FaqTopic('Trips & documents', [
    FaqEntry(
      'Where do I find my e-ticket?',
      'On the booking’s page, once your agent uploads it. You also get a '
          'notification when it arrives.',
    ),
    FaqEntry(
      'What if something on my ticket is wrong?',
      'On the booking’s page, choose Request a correction and describe what '
          'is wrong; the agent fixes it and uploads a new ticket. If it cannot '
          'be resolved, raise a support ticket from the same page.',
    ),
  ]),
];
