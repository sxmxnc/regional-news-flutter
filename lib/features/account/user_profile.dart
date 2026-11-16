import '../subscription/subscription_status.dart';

final class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.subscription = const SubscriptionStatus.none(),
    this.shipping = const ShippingAddress(),
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;

  final SubscriptionStatus subscription;

  final ShippingAddress shipping;
}

final class ShippingAddress {
  const ShippingAddress({
    this.name = '',
    this.street = '',
    this.postcode = '',
    this.city = '',
    this.country = '',
    this.phone = '',
  });

  final String name;
  final String street;
  final String postcode;
  final String city;
  final String country;
  final String phone;
}
