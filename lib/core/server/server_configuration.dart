import 'dart:io';

class ServerConfiguration {
  final InternetAddress address;
  final int port;
  ServerConfiguration({required this.address, required this.port});
}

final defaultServerConfiguration = ServerConfiguration(
  address: InternetAddress.anyIPv4,
  port: 5575,
);
