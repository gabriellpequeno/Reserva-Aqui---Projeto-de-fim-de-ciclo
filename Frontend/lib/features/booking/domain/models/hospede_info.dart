/// Dados do hóspede (quem efetivamente vai se hospedar).
/// Usado tanto para guest quanto para user autenticado reservando pra terceiro.
/// Campos são sempre despmascarados (apenas dígitos em CPF/telefone).
class HospedeInfoFormData {
  final String nome;
  final String email;
  final String cpf;       // 11 dígitos
  final String telefone;  // 10 ou 11 dígitos

  const HospedeInfoFormData({
    required this.nome,
    required this.email,
    required this.cpf,
    required this.telefone,
  });

  /// True se algum campo diverge do passado (user editou o pré-preenchimento).
  bool hasDivergedFrom(HospedeInfoFormData? original) {
    if (original == null) return true;
    return nome     != original.nome
        || email    != original.email
        || cpf      != original.cpf
        || telefone != original.telefone;
  }

  @override
  bool operator ==(Object other) =>
      other is HospedeInfoFormData &&
      other.nome     == nome   &&
      other.email    == email  &&
      other.cpf      == cpf    &&
      other.telefone == telefone;

  @override
  int get hashCode => Object.hash(nome, email, cpf, telefone);
}
