/**
 * Entity: Usuario
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 */
export class Usuario {
  constructor(
    public nome_completo:   string,
    public email:           string,
    public senha:           string,
    public cpf:             string,
    public data_nascimento: string,
    public numero_celular?: string,
  ) {}

  // ── Validators ───────────────────────────────────────────────────────────────

  private static validateEmail(email: string): void {
    if (!email.includes('@') || !email.includes('.com'))
      throw new Error('Email inválido: deve conter @ e .com');
  }

  private static validateSenha(senha: string): void {
    const ok =
      /[A-Z]/.test(senha) &&
      /[a-z]/.test(senha) &&
      /@/.test(senha) &&
      /[0-9]/.test(senha);
    if (!ok)
      throw new Error('Senha fraca: requer letra maiúscula, minúscula, @ e número');
  }

  private static validateCpf(cpf: string): void {
    const digits = cpf.replace(/\D/g, '');
    if (!/^\d{11}$/.test(digits))
      throw new Error('CPF inválido: deve conter 11 dígitos');
  }

  private static validateDataNascimento(data: string): void {
    if (!/^\d{2}\/\d{2}\/\d{4}$/.test(data))
      throw new Error('Data de nascimento inválida: formato esperado dd/mm/aaaa');
  }

  private static validateCelular(cel: string): void {
    // Aceita: (xx) x xxxx-xxxx ou (xx) xxxxx-xxxx
    if (!/^\(\d{2}\) \d{4,5}-\d{4}$/.test(cel))
      throw new Error('Celular inválido: formato esperado (xx) xxxx-xxxx ou (xx) xxxxx-xxxx');
  }

  /** Executa todos os validadores obrigatórios. Lança erro no primeiro que falhar. */
  static validate(input: {
    nome_completo:   string;
    email:           string;
    senha:           string;
    cpf:             string;
    data_nascimento: string;
    numero_celular?: string;
  }): void {
    this.validateEmail(input.email);
    this.validateSenha(input.senha);
    this.validateCpf(input.cpf);
    this.validateDataNascimento(input.data_nascimento);
    if (input.numero_celular) this.validateCelular(input.numero_celular);
  }

  /** Validação parcial para updates — só valida os campos presentes. */
  static validatePartial(input: Partial<{
    email:           string;
    nome_completo:   string;
    numero_celular:  string;
    data_nascimento: string;
  }>): void {
    if (input.email)           this.validateEmail(input.email);
    if (input.data_nascimento) this.validateDataNascimento(input.data_nascimento);
    if (input.numero_celular)  this.validateCelular(input.numero_celular);
  }

  /** Validação de troca de senha. */
  static validateNovaSenha(senha: string): void {
    this.validateSenha(senha);
  }
}
