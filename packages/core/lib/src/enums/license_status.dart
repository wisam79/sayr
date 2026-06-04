/// License status - states of a license code.
///
/// A license is an 8-character code that grants a student
/// access to a route subscription.
enum LicenseStatus {
  /// Available for activation
  active,

  /// Marked as used (subscription created)
  used,

  /// Expired (past valid_days)
  expired,

  /// Revoked by admin
  revoked;

  /// Whether the license can be activated.
  bool get isActivatable => this == LicenseStatus.active;

  /// Parse from database string value.
  static LicenseStatus fromString(String value) {
    return LicenseStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LicenseStatus.expired,
    );
  }
}
