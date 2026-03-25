import 'dart:convert';

class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.firebaseUid,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? firebaseUid;

  factory ClientProfile.fromMap(Map<String, dynamic> map) {
    return ClientProfile(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: (map['name'] as String? ?? '').trim(),
      email: (map['email'] as String? ?? '').trim(),
      phone: (map['phone'] as String?)?.trim(),
      firebaseUid: (map['firebase_uid'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'firebase_uid': firebaseUid,
    };
  }
}

class ClientSession {
  const ClientSession({
    required this.token,
    required this.client,
    this.migratedToFirebase = false,
    this.firebaseSignInProvider,
  });

  final String token;
  final ClientProfile client;
  final bool migratedToFirebase;
  final String? firebaseSignInProvider;

  factory ClientSession.fromMap(Map<String, dynamic> map) {
    return ClientSession(
      token: (map['token'] as String? ?? '').trim(),
      client: ClientProfile.fromMap(
        Map<String, dynamic>.from(map['client'] as Map? ?? <String, dynamic>{}),
      ),
      migratedToFirebase: map['migratedToFirebase'] as bool? ?? false,
      firebaseSignInProvider:
          (map['firebaseSignInProvider'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'token': token,
      'client': client.toMap(),
      'migratedToFirebase': migratedToFirebase,
      'firebaseSignInProvider': firebaseSignInProvider,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory ClientSession.fromJson(String source) {
    return ClientSession.fromMap(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }
}
