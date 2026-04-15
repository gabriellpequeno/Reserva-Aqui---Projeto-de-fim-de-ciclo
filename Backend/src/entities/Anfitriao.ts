/**
 * Entity: Anfitriao
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 */
export class Anfitriao {
  constructor(
    public nome_hotel:  string,
    public cnpj:        string,
    public telefone:    string,
    public email:       string,
    public senha:       string,
    public cep:         string,
    public uf:          string,
    public cidade:      string,
    public bairro:      string,
    public rua:         string,
    public numero:      string,
    public complemento?: string,
    public descricao?:   string,
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

  private static validateCnpj(cnpj: string): void {
    const digits = cnpj.replace(/\D/g, '');
    if (!/^\d{14}$/.test(digits))
      throw new Error('CNPJ inválido: deve conter 14 dígitos');
  }

  private static validateCep(cep: string): void {
    const digits = cep.replace(/\D/g, '');
    if (!/^\d{8}$/.test(digits))
      throw new Error('CEP inválido: deve conter 8 dígitos');
  }

  private static validateUf(uf: string): void {
    if (!/^[A-Z]{2}$/.test(uf.toUpperCase()))
      throw new Error('UF inválida: deve conter 2 letras (ex: SP, RJ)');
  }

  /** Executa todos os validadores obrigatórios. Lança erro no primeiro que falhar. */
  static validate(input: {
    nome_hotel:  string;
    cnpj:        string;
    telefone:    string;
    email:       string;
    senha:       string;
    cep:         string;
    uf:          string;
    cidade:      string;
    bairro:      string;
    rua:         string;
    numero:      string;
    complemento?: string;
    descricao?:   string;
  }): void {
    this.validateEmail(input.email);
    this.validateSenha(input.senha);
    this.validateCnpj(input.cnpj);
    this.validateCep(input.cep);
    this.validateUf(input.uf);
  }

  /** Validação parcial para updates — só valida os campos presentes. */
  static validatePartial(input: Partial<{
    email:       string;
    nome_hotel:  string;
    telefone:    string;
    descricao:   string;
    cep:         string;
    uf:          string;
    cidade:      string;
    bairro:      string;
    rua:         string;
    numero:      string;
    complemento: string;
  }>): void {
    if (input.email) this.validateEmail(input.email);
    if (input.cep)   this.validateCep(input.cep);
    if (input.uf)    this.validateUf(input.uf);
  }

  /** Validação de troca de senha. */
  static validateNovaSenha(senha: string): void {
    this.validateSenha(senha);
  }
}
