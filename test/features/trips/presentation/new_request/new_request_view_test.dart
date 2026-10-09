import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/theme/app_theme.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/usecases/post_trip_request.dart';
import 'package:tripbybid/features/trips/domain/usecases/search_places.dart';
import 'package:tripbybid/features/trips/presentation/new_request/new_request_cubit.dart';
import 'package:tripbybid/features/trips/presentation/new_request/new_request_view.dart';
import 'package:tripbybid/features/trips/presentation/new_request/place_search_cubit.dart';

import '../../trips_fakes.dart';
import 'new_request_fakes.dart';

void main() {
  late NewRequestCubit cubit;
  late PlaceSearchCubit search;

  setUp(() {
    cubit = NewRequestCubit(
      postTrip: PostTripRequestUseCase(FakeTripsRepository()),
      clock: () => DateTime(2026, 10, 10),
    )..start(email: 'asha@example.com', phone: '+919810043210');
    search = PlaceSearchCubit(
      searchPlaces: SearchPlacesUseCase(FakePlacesRepository()),
      debounce: Duration.zero,
    );
  });

  tearDown(() async {
    await cubit.close();
    await search.close();
  });

  Future<void> pumpView(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: search),
          ],
          child: const NewRequestView(),
        ),
      ),
    );
  }

  testWidgets('step 1 shows the design copy for flights', (tester) async {
    await pumpView(tester);

    expect(find.text('STEP 1 OF 2'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Travellers'), findsOneWidget);
    expect(find.text('YOUR BUDGET'), findsOneWidget);
    expect(find.text('₹20,000'), findsOneWidget);
    expect(find.text('total, all travellers'), findsOneWidget);
    expect(find.byKey(const Key('route-swap')), findsOneWidget);
  });

  testWidgets('switching type changes the labels and budget', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();
    expect(find.text('From station'), findsOneWidget);
    expect(find.text('To station'), findsOneWidget);
    expect(find.text('Passengers'), findsOneWidget);
    expect(find.text('₹4,500'), findsOneWidget);

    await tester.tap(find.text('Hotel'));
    await tester.pumpAndSettle();
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Area'), findsOneWidget);
    expect(find.text('Guests'), findsOneWidget);
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('total stay'), findsOneWidget);
    expect(find.byKey(const Key('route-swap')), findsNothing);
  });

  testWidgets('the swap button swaps origin and destination', (tester) async {
    cubit
      ..setFrom(FakePlacesRepository.mumbai)
      ..setTo(FakePlacesRepository.dubai);
    await pumpView(tester);

    Finder inRow(String key, String text) =>
        find.descendant(of: find.byKey(Key(key)), matching: find.text(text));
    expect(inRow('route-from', 'Mumbai (BOM)'), findsOneWidget);
    expect(inRow('route-to', 'Dubai (DXB)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('route-swap')));
    await tester.pumpAndSettle();

    expect(inRow('route-from', 'Dubai (DXB)'), findsOneWidget);
    expect(inRow('route-to', 'Mumbai (BOM)'), findsOneWidget);
  });

  testWidgets('large text does not overflow either step', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    cubit
      ..setFrom(FakePlacesRepository.mumbai)
      ..setTo(FakePlacesRepository.dubai)
      ..setDepartDate(DateTime(2026, 11, 12))
      ..setRoundTrip(true)
      ..setReturnDate(DateTime(2026, 11, 20))
      ..setExactBudget(1234567);
    await pumpView(tester);
    await tester.tap(find.byKey(const Key('new-request-continue')));
    await tester.pumpAndSettle();
    expect(find.text('STEP 2 OF 2'), findsOneWidget);

    cubit
      ..backToRoute()
      ..selectType(TripType.hotel);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the traveller stepper counts up', (tester) async {
    await pumpView(tester);
    await tester.tap(find.byTooltip('More travellers'));
    await tester.pump();
    expect(cubit.state.adults, 2);
  });

  testWidgets('continue explains what is missing', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byKey(const Key('new-request-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Choose where you are flying from.'), findsOneWidget);
    expect(find.text('Pick your travel date.'), findsOneWidget);
    expect(find.text('STEP 1 OF 2'), findsOneWidget);
  });

  testWidgets('a place is picked from the search screen', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byKey(const Key('route-to')));
    await tester.pumpAndSettle();
    expect(find.text('Popular'.toUpperCase()), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'dxb');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dubai International Airport'));
    await tester.pumpAndSettle();

    expect(cubit.state.to, FakePlacesRepository.dubai);
    expect(find.text('Dubai (DXB)'), findsOneWidget);
  });

  testWidgets('step 2 shows details and contact for a valid route', (
    tester,
  ) async {
    cubit
      ..setFrom(FakePlacesRepository.mumbai)
      ..setTo(FakePlacesRepository.dubai)
      ..setDepartDate(DateTime(2026, 11, 12));
    await pumpView(tester);

    await tester.tap(find.byKey(const Key('new-request-continue')));
    await tester.pumpAndSettle();

    expect(find.text('STEP 2 OF 2'), findsOneWidget);
    expect(find.text('Cabin class'), findsOneWidget);
    expect(find.text('Premium economy'), findsOneWidget);
    expect(find.text('98100 43210'), findsOneWidget);
    expect(find.text('asha@example.com'), findsOneWidget);
    expect(find.text('Post request'), findsOneWidget);
    expect(cubit.state.type, TripType.flight);
  });
}
