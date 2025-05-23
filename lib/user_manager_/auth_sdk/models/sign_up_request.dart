class SignUpRequest {
  final String username;
  final String password;
  final String email;

  SignUpRequest({
    required this.username,
    required this.password,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
    };
  }
}
