import 'package:flutter/material.dart';

/// A fake transaction shown in the "Recent" list. Purely for display — these
/// are not real payments and are intentionally not interactive.
class Txn {
  const Txn({
    required this.merchant,
    required this.category,
    required this.amount,
    required this.when,
    required this.icon,
  });

  final String merchant;
  final String category;
  final double amount; // negative = spent, positive = received
  final String when;
  final IconData icon;

  /// Sample data used to populate the home screen.
  static const List<Txn> samples = [
    Txn(
      merchant: 'Aurora Coffee',
      category: 'Food & Drink',
      amount: -4.80,
      when: 'Today, 08:12',
      icon: Icons.local_cafe_rounded,
    ),
    Txn(
      merchant: 'Nimbus Transit',
      category: 'Travel',
      amount: -2.75,
      when: 'Today, 07:45',
      icon: Icons.tram_rounded,
    ),
    Txn(
      merchant: 'Payroll Deposit',
      category: 'Income',
      amount: 2450.00,
      when: 'Yesterday',
      icon: Icons.account_balance_rounded,
    ),
    Txn(
      merchant: 'Lumen Grocers',
      category: 'Groceries',
      amount: -63.20,
      when: 'Yesterday',
      icon: Icons.shopping_basket_rounded,
    ),
    Txn(
      merchant: 'Orbit Cinema',
      category: 'Entertainment',
      amount: -18.00,
      when: 'Mon',
      icon: Icons.movie_rounded,
    ),
  ];
}
