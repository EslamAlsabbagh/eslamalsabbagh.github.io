abstract interface class AuthRepo {
  Future<String?> login(String code, String password);
  Future<bool> signup(String password, String email);
  Future<bool> createEmployeeAuthAccount(String password, String email);
  Future<void> updatePassword(
    String code,
    String oldPassword,
    String newPassword,
    String confirmPassword,
  );
  Future<void> resetEmployeePassword(String employeeCode);
}
