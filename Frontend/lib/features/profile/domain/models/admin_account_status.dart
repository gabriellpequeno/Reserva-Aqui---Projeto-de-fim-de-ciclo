/// Status que uma conta pode ter do ponto de vista do admin.
///
/// - [ativo]    — conta ativa, visível e operacional.
/// - [suspenso] — usuário (hóspede) suspenso por moderação.
/// - [inativo]  — hotel desativado na plataforma.
///
/// `suspenso` só aparece em [AdminUserModel]; `inativo` só em [AdminHotelModel].
/// Valores desconhecidos vindos do backend caem em [ativo] como fallback seguro.
enum AdminAccountStatus {
  ativo,
  suspenso,
  inativo;

  static AdminAccountStatus fromString(String? value) {
    switch (value) {
      case 'ativo':
        return AdminAccountStatus.ativo;
      case 'suspenso':
        return AdminAccountStatus.suspenso;
      case 'inativo':
        return AdminAccountStatus.inativo;
      default:
        return AdminAccountStatus.ativo;
    }
  }

  String toApiValue() => name;
}
