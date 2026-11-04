// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:product_app/main.dart';

void main() {
  final sampleProducts = <Map<String, dynamic>>[
    {'name': 'Cedar Mug', 'price': 12.50},
    {'name': 'Harvest Tea', 'price': 18.00},
    {'name': 'amber Candle', 'price': 20.00},
    {'name': 'Wool Scarf', 'price': 28.00},
    {'name': 'Autumn Sample', 'price': 8.00},
  ];

  testWidgets('Product editor rejects empty name and invalid price', (
    WidgetTester tester,
  ) async {
    final firestore = FakeFirebaseFirestore();

    // Build the product editor with an in-memory Firestore collection.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductEditor(products: firestore.collection('products')),
        ),
      ),
    );

    // An empty name and price must both be rejected.
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Enter a product name'), findsOneWidget);
    expect(find.text('Enter a finite price of zero or more'), findsOneWidget);

    // Invalid input must not create a product.
    final snapshot = await firestore.collection('products').get();
    expect(snapshot.docs, isEmpty);
  });

  testWidgets('Creating a product stores its name and numeric price', (
    WidgetTester tester,
  ) async {
    final firestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductEditor(products: firestore.collection('products')),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Cedar Mug',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price'),
      '12.50',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final snapshot = await firestore.collection('products').get();

    expect(snapshot.docs.length, 1);
    expect(snapshot.docs.first.id, isNotEmpty);
    expect(snapshot.docs.first.data()['name'], 'Cedar Mug');
    expect(snapshot.docs.first.data()['price'], 12.50);
  });

  testWidgets('Updating a product preserves its document ID', (
    WidgetTester tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    final products = firestore.collection('products');

    final reference = await products.add({'name': 'Cedar Mug', 'price': 12.50});

    final original = await products.get();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductEditor(
            products: products,
            document: original.docs.first,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price'),
      '14.00',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final updated = await reference.get();

    expect(updated.exists, isTrue);
    expect(updated.id, reference.id);
    expect(updated.data()?['name'], 'Cedar Mug');
    expect(updated.data()?['price'], 14.00);

    final snapshot = await products.get();
    expect(snapshot.docs.length, 1);
  });

  testWidgets('Deleting a product requires confirmation', (
    WidgetTester tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    final products = firestore.collection('products');

    await products.add({'name': 'Temporary Product', 'price': 5.00});

    await tester.pumpWidget(MaterialApp(home: ProductPage(products: products)));
    await tester.pumpAndSettle();

    expect(find.text('Temporary Product'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete product'));
    await tester.pumpAndSettle();

    expect(find.text('Delete product?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect((await products.get()).docs.length, 1);

    await tester.tap(find.byTooltip('Delete product'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect((await products.get()).docs, isEmpty);
    expect(find.text('No products yet. Add one to begin.'), findsOneWidget);
  });

  test('Name search ignores case and matches partial names', () {
    final product = {'name': 'Cedar Mug', 'price': 12.50};

    expect(productMatchesFilters(product, searchText: 'CEDAR'), isTrue);
    expect(productMatchesFilters(product, searchText: 'mug'), isTrue);
    expect(productMatchesFilters(product, searchText: '  cedar  '), isTrue);
    expect(productMatchesFilters(product, searchText: 'tea'), isFalse);
  });

  test('Minimum and maximum prices use inclusive boundaries', () {
    final product = {'name': 'Cedar Mug', 'price': 12.50};

    expect(
      productMatchesFilters(product, minPrice: 12.50, maxPrice: 12.50),
      isTrue,
    );

    expect(productMatchesFilters(product, minPrice: 12.51), isFalse);

    expect(productMatchesFilters(product, maxPrice: 12.49), isFalse);

    expect(productMatchesFilters(product, minPrice: 0), isTrue);
  });

  test('Combined name and price filtering uses AND logic', () {
    final matches = sampleProducts.where((product) {
      return productMatchesFilters(
        product,
        searchText: 'tea',
        minPrice: 12.50,
        maxPrice: 20.00,
      );
    }).toList();

    expect(matches.length, 1);
    expect(matches.first['name'], 'Harvest Tea');
  });

  test('Price filtering matches the five sample products', () {
    final middleRange = sampleProducts.where((product) {
      return productMatchesFilters(product, minPrice: 12.50, maxPrice: 20.00);
    }).toList();

    expect(
      middleRange.map((product) => product['name']).toList(),
      containsAll(['Cedar Mug', 'Harvest Tea', 'amber Candle']),
    );
    expect(middleRange.length, 3);

    final exactBoundary = sampleProducts.where((product) {
      return productMatchesFilters(product, minPrice: 12.50, maxPrice: 12.50);
    }).toList();

    expect(exactBoundary.length, 1);
    expect(exactBoundary.first['name'], 'Cedar Mug');
  });

  testWidgets('Reset clears search and both price filters', (
    WidgetTester tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    final products = firestore.collection('products');

    await products.add({'name': 'Cedar Mug', 'price': 12.50});
    await products.add({'name': 'Harvest Tea', 'price': 18.00});

    await tester.pumpWidget(MaterialApp(home: ProductPage(products: products)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search products'),
      'cedar',
    );

    await tester.enterText(find.widgetWithText(TextField, 'Min price'), '12');

    await tester.enterText(find.widgetWithText(TextField, 'Max price'), '15');

    await tester.pumpAndSettle();

    expect(find.text('Cedar Mug'), findsOneWidget);
    expect(find.text('Harvest Tea'), findsNothing);

    await tester.ensureVisible(find.text('Reset'));
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();

    expect(fields.length, 3);
    expect(fields[0].controller!.text, isEmpty);
    expect(fields[1].controller!.text, isEmpty);
    expect(fields[2].controller!.text, isEmpty);

    expect(find.text('Cedar Mug'), findsOneWidget);
    expect(find.text('Harvest Tea'), findsOneWidget);
  });

  test('Invalid product data and invalid filter bounds do not match', () {
    expect(productMatchesFilters({'name': '', 'price': 12.50}), isFalse);

    expect(
      productMatchesFilters({'name': 'Cedar Mug', 'price': '12.50'}),
      isFalse,
    );

    expect(
      productMatchesFilters(
        {'name': 'Cedar Mug', 'price': 12.50},
        minPrice: 30,
        maxPrice: 10,
      ),
      isFalse,
    );
  });
}
