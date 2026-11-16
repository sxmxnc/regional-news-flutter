import '../../features/account/user_profile.dart';
import 'json_fields.dart';
import 'subscription_mapper.dart';

abstract final class UserMapper {
  static UserProfile? fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? user = jsonMapOrNull(json['user']);
    if (user == null) return null;

    final String? email = jsonString(user['email']);
    if (email == null) return null;

    return UserProfile(
      firstName: jsonString(user['first_name']) ?? '',
      lastName: jsonString(user['last_name']) ?? '',
      email: email,
      username: jsonString(user['username']) ?? '',
      subscription: SubscriptionMapper.fromUser(
        jsonMapOrNull(json['subscription']),
      ),
      shipping: ShippingAddress(
        name: jsonString(user['wbapi_ship_name']) ?? '',
        street: jsonString(user['wbapi_ship_street']) ?? '',
        postcode: jsonString(user['wbapi_ship_postcode']) ?? '',
        city: jsonString(user['wbapi_ship_city']) ?? '',
        country: jsonString(user['wbapi_ship_country']) ?? '',
        phone: jsonString(user['wbapi_ship_phone']) ?? '',
      ),
    );
  }
}
