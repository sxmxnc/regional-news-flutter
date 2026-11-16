import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/failure.dart';

/// Der HTTP-Kanal, den beide Clients teilen. Als Provider, damit Tests einen
/// `MockClient` einsetzen können, ohne dass Produktivcode davon weiß.
final Provider<http.Client> httpClientProvider = Provider<http.Client>((
  Ref ref,
) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return client;
});

Future<T> mapTransportErrors<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on SocketException catch (error) {
    throw ConnectionFailure(cause: error);
  } on TimeoutException catch (error) {
    throw ConnectionFailure(cause: error);
  } on http.ClientException catch (error) {
    throw ConnectionFailure(cause: error);
  } on HandshakeException catch (error) {
    throw ConnectionFailure(cause: error);
  }
}
