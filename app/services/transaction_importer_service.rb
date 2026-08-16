require "roo"

class TransactionImporterService
  Result = Struct.new(:success_count, :error_count, :errors, keyword_init: true)

  HEADER_MAP = {
    date: [ "data", "date", "dt", "data transacao", "data transação" ],
    competence_date: [ "competencia", "competência", "data_competencia", "data_competência", "fatura", "data competencia", "data competência", "data de competencia", "data de competência", "competencia/fatura", "competência/fatura", "fatura/competencia" ],
    description: [ "descrição", "descricao", "description", "historico", "histórico", "detalhe", "memorando" ],
    amount: [ "valor", "amount", "val", "quantia" ],
    type: [ "tipo", "type", "natureza", "operacao", "operação" ],
    category: [ "categoria", "category" ],
    supplier: [ "fornecedor", "cliente", "supplier", "payee", "local", "estabelecimentos" ],
    cost_center: [ "centro_de_custo", "cost_center", "centro de custo" ],
    bank_account: [ "banco", "bank", "bank_account", "conta", "conta bancaria", "conta bancária", "conta_bancaria" ],
    credit_card: [ "cartao", "cartão", "credit_card", "cartao_de_credito", "cartão de crédito", "cartao de credito", "cartao_credito" ],
    is_refund: [ "estorno", "reembolso", "is_refund", "refund" ],
    current_installment: [ "parcela_atual", "parcela atual", "parc_atual", "parc atual", "current_installment", "num_parcela", "número parcela", "n_parcela" ],
    total_installments: [ "parcela_total", "parcela total", "total_parcelas", "total de parcelas", "parcelas_total", "parc_total", "parc total", "qtd_parcelas", "qtd parcelas", "quantidade parcelas", "numero_parcelas", "número parcelas", "total_installments", "installments_count", "installments", "parcelas" ]
  }.freeze

  def initialize(file_path:, filename:, account:, bank_account_id: nil, credit_card_id: nil)
    @file_path = file_path
    @filename = filename
    @account = account
    @bank_account_id = bank_account_id.presence
    @credit_card_id = credit_card_id.presence
  end

  def parse_preview
    spreadsheet = open_spreadsheet
    return { errors: [ "Formato de arquivo não suportado" ], rows: [] } unless spreadsheet

    begin
      sheet = spreadsheet.sheet(0)
      rows = sheet.to_a
    rescue StandardError => e
      return { errors: [ "Não foi possível ler o arquivo CSV. Verifique a formatação do arquivo (#{e.message})" ], rows: [] }
    end

    return { errors: [], rows: [] } if rows.empty?

    headers = extract_headers(rows.first)
    data_rows = rows.drop(1)
    preview_rows = []

    categories = @account.categories.order(:name)
    suppliers = @account.suppliers.order(:name)
    cost_centers = @account.cost_centers.order(:name)
    bank_accounts = @account.bank_accounts.order(:name)
    credit_cards = @account.credit_cards.order(:name)

    data_rows.each_with_index do |row, _index|
      next if row.all?(&:nil?) || row.all? { |c| c.to_s.strip.empty? }

      row_data = map_row_to_headers(headers, row)

      raw_amount, is_negative = parse_amount(row_data[:amount])
      tx_type = determine_transaction_type(row_data[:type], is_negative)
      parsed_date = parse_date(row_data[:date]) || Date.current
      parsed_competence_date = parse_date(row_data[:competence_date])
      description = row_data[:description].to_s.strip.presence || "Lançamento Importado"

      cat_name = row_data[:category].to_s.strip
      cat = categories.find { |c| c.name.casecmp?(cat_name) } if cat_name.present?

      sup_name = row_data[:supplier].to_s.strip
      sup = suppliers.find { |s| s.name.casecmp?(sup_name) } if sup_name.present?

      cc_name = row_data[:cost_center].to_s.strip
      cc = cost_centers.find { |c| c.name.casecmp?(cc_name) } if cc_name.present?

      bank_name = row_data[:bank_account].to_s.strip
      matched_bank = bank_accounts.find { |b| b.name.casecmp?(bank_name) } if bank_name.present?
      matched_bank ||= bank_accounts.find_by(id: @bank_account_id) if @bank_account_id.present?
      matched_bank ||= bank_accounts.first

      card_name = row_data[:credit_card].to_s.strip
      matched_card = credit_cards.find { |c| c.name.casecmp?(card_name) } if card_name.present?
      matched_card ||= credit_cards.find_by(id: @credit_card_id) if @credit_card_id.present?

      parsed_competence_date = if matched_card.present?
                                 matched_card.invoice_competence_for(parsed_date)
                               else
                                 parse_date(row_data[:competence_date]) || parsed_date
                               end

      is_refund_flag = determine_is_refund(row_data)
      current_inst, total_inst = parse_installments_info(row_data)

      preview_rows << {
        date: parsed_date.strftime("%d/%m/%Y"),
        competence_date: parsed_competence_date&.strftime("%d/%m/%Y"),
        description: description,
        amount: raw_amount,
        transaction_type: tx_type,
        is_refund: is_refund_flag,
        current_installment: current_inst,
        total_installments: total_inst,
        installments_count: total_inst,
        category: {
          name: cat_name.presence || (cat&.name || "Alimentação"),
          id: cat&.id,
          is_new: cat.nil?
        },
        supplier: {
          name: sup_name.presence || (sup&.name || "Geral"),
          id: sup&.id,
          is_new: sup.nil?
        },
        cost_center: {
          name: cc_name,
          id: cc&.id,
          is_new: cc_name.present? && cc.nil?
        },
        bank_account: {
          name: bank_name.presence || matched_bank&.name,
          id: matched_bank&.id,
          is_new: bank_name.present? && matched_bank.nil?
        },
        credit_card: {
          name: card_name.presence || matched_card&.name,
          id: matched_card&.id,
          is_new: card_name.present? && matched_card.nil?
        }
      }
    end

    { errors: [], rows: preview_rows }
  end

  def call
    success_count = 0
    error_count = 0
    errors = []

    spreadsheet = open_spreadsheet
    return Result.new(success_count: 0, error_count: 1, errors: [ "Formato de arquivo não suportado" ]) unless spreadsheet

    sheet = spreadsheet.sheet(0)
    rows = sheet.to_a
    return Result.new(success_count: 0, error_count: 0, errors: []) if rows.empty?

    headers = extract_headers(rows.first)
    data_rows = rows.drop(1)

    data_rows.each_with_index do |row, index|
      next if row.all?(&:nil?) || row.all? { |c| c.to_s.strip.empty? }

      row_data = map_row_to_headers(headers, row)

      transaction_attributes = build_transaction_attributes(row_data)
      current_inst, total_inst = parse_installments_info(row_data)

      if total_inst > 1
        creator = InstallmentTransactionCreator.new(
          account: @account,
          base_params: transaction_attributes.except(:amount),
          total_installments: total_inst,
          current_installment: current_inst,
          amount_per_installment: transaction_attributes[:amount]
        )
        created = creator.call
        if created.present?
          success_count += created.size
        else
          error_count += 1
          errors << "Linha #{index + 2}: Não foi possível criar as parcelas (#{current_inst}/#{total_inst})."
        end
      else
        transaction = @account.transactions.build(transaction_attributes)
        if transaction.save
          success_count += 1
        else
          error_count += 1
          errors << "Linha #{index + 2}: #{transaction.errors.full_messages.join(', ')}"
        end
      end
    rescue StandardError => e
      error_count += 1
      errors << "Linha #{index + 2}: #{e.message}"
    end

    Result.new(success_count: success_count, error_count: error_count, errors: errors)
  end

  private

  def open_spreadsheet
    ext = File.extname(@filename).downcase
    case ext
    when ".csv"
      detect_csv_spreadsheet
    when ".xlsx"
      Roo::Excelx.new(@file_path)
    when ".xls"
      Roo::Excel.new(@file_path)
    else
      nil
    end
  end

  def detect_csv_spreadsheet
    first_line = File.open(@file_path, "r:bom|utf-8", &:readline) rescue ""

    col_sep = if first_line.count(";") > first_line.count(",")
                ";"
              elsif first_line.count("\t") > first_line.count(",")
                "\t"
              else
                ","
              end

    Roo::CSV.new(@file_path, csv_options: { col_sep: col_sep, liberal_parsing: true })
  rescue StandardError
    alt_sep = (defined?(col_sep) && col_sep == ";") ? "," : ";"
    Roo::CSV.new(@file_path, csv_options: { col_sep: alt_sep, liberal_parsing: true }) rescue Roo::CSV.new(@file_path)
  end

  def extract_headers(first_row)
    first_row.map do |cell|
      raw = cell.to_s.strip.downcase
      norm = ActiveSupport::Inflector.transliterate(raw).gsub(/[^a-z0-9]/, "")

      match = HEADER_MAP.find do |_key, aliases|
        aliases.any? do |a|
          a_raw = a.to_s.strip.downcase
          a_norm = ActiveSupport::Inflector.transliterate(a_raw).gsub(/[^a-z0-9]/, "")
          raw == a_raw || norm == a_norm
        end
      end

      match&.first || raw.to_sym
    end
  end

  def map_row_to_headers(headers, row)
    data = {}
    headers.each_with_index do |header_key, idx|
      data[header_key] = row[idx] if header_key.is_a?(Symbol)
    end
    data
  end

  def build_transaction_attributes(data)
    raw_amount, is_negative_amount = parse_amount(data[:amount])
    tx_type = determine_transaction_type(data[:type], is_negative_amount)
    parsed_date = parse_date(data[:date]) || Date.current
    description = data[:description].to_s.strip.presence || "Lançamento Importado"

    category = find_or_create_category(data[:category])
    supplier = find_or_create_supplier(data[:supplier])
    cost_center = find_or_create_cost_center(data[:cost_center])

    payment_attrs = assign_payment_source(data, tx_type)

    parsed_competence_date = if payment_attrs[:credit_card].present?
                               payment_attrs[:credit_card].invoice_competence_for(parsed_date)
                             else
                               parse_date(data[:competence_date]) || parsed_date
                             end

    is_refund_val = determine_is_refund(data)

    attrs = {
      transaction_type: tx_type,
      amount: raw_amount,
      description: description,
      date: parsed_date,
      competence_date: parsed_competence_date,
      category: category,
      supplier: supplier,
      cost_center: cost_center,
      status: "realized",
      is_refund: (payment_attrs[:credit_card].present? && is_refund_val)
    }.merge(payment_attrs)

    attrs
  end

  def determine_is_refund(data)
    ref_val = data[:is_refund].to_s.strip
    return true if ref_val =~ /\A(sim|true|1|s|estorno|reembolso)\z/i

    desc = data[:description].to_s.strip
    type_str = data[:type].to_s.strip
    (desc =~ /(estorno|reembolso)/i || type_str =~ /(estorno|reembolso)/i) ? true : false
  end

  def parse_installments_info(row_data)
    curr = nil
    tot = nil

    if row_data[:current_installment].present?
      c_val = row_data[:current_installment].to_s.strip
      if c_val =~ %r{(\d+)/(\d+)}
        curr = $1.to_i
        tot = $2.to_i
      elsif c_val =~ /(\d+)/
        curr = $1.to_i
      end
    end

    if row_data[:total_installments].present? || row_data[:installments_count].present?
      t_val = (row_data[:total_installments] || row_data[:installments_count]).to_s.strip
      if t_val =~ %r{(\d+)/(\d+)}
        curr ||= $1.to_i
        tot ||= $2.to_i
      elsif t_val =~ /(\d+)/
        tot ||= $1.to_i
      end
    end

    if desc = row_data[:description].to_s.strip.presence
      if desc =~ %r{\(?(\d+)/(\d+)\)?}
        curr ||= $1.to_i
        tot ||= $2.to_i
      elsif desc =~ /\b(\d+)\s*x\b/i
        tot ||= $1.to_i
      end
    end

    current_inst = [ curr || 1, 1 ].max
    total_inst = [ tot || current_inst, current_inst ].max

    [ current_inst, total_inst ]
  end

  def parse_amount(val)
    return [ 0.0, false ] if val.nil?

    if val.is_a?(Numeric)
      is_negative = val.negative?
      return [ val.abs.to_f, is_negative ]
    end

    str = val.to_s.strip.gsub(/[R$\s]/, "")
    is_negative = str.start_with?("-")
    str = str.delete("-")

    if str.include?(",") && str.include?(".")
      str = str.tr(".", "").tr(",", ".")
    elsif str.include?(",")
      str = str.tr(",", ".")
    end

    [ str.to_f.abs, is_negative ]
  end

  def determine_transaction_type(type_val, is_negative)
    type_str = type_val.to_s.strip.downcase

    if type_str =~ /(transferencia|transferência|transf|transfer)/
      return "transfer"
    end

    return "expense" if is_negative

    if type_str =~ /(despesa|saida|saída|expense|debito|débito)/
      "expense"
    else
      "income"
    end
  end

  def self.parse_date(val)
    return nil if val.blank?
    return val.to_date if val.is_a?(Date) || val.is_a?(Time) || val.is_a?(DateTime)

    str = val.to_s.strip
    return nil if str.empty?

    # 1. ISO format: YYYY-MM-DD or YYYY/MM/DD (with optional time or T)
    if str =~ %r{\A(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})(?:\s+|\z|T)}
      year, month, day = $1.to_i, $2.to_i, $3.to_i
      return Date.new(year, month, day) rescue nil
    end

    # 2. Brazilian / European format: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY (4-digit year, optional time or T)
    if str =~ %r{\A(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})(?:\s+|\z|T)}
      day, month, year = $1.to_i, $2.to_i, $3.to_i
      return Date.new(year, month, day) rescue nil
    end

    # 3. 2-digit year format: DD/MM/YY, DD-MM-YY, DD.MM.YY (optional time or T)
    if str =~ %r{\A(\d{1,2})[/.-](\d{1,2})[/.-](\d{2})(?:\s+|\z|T)}
      day, month, short_year = $1.to_i, $2.to_i, $3.to_i
      year = short_year + (short_year >= 70 ? 1900 : 2000)
      return Date.new(year, month, day) rescue nil
    end

    # 4. Month/Year format: MM/YYYY or MM-YYYY or MM.YYYY (e.g. 08/2026 or 8/2026)
    if str =~ %r{\A(\d{1,2})[/.-](\d{4})\z}
      month, year = $1.to_i, $2.to_i
      return Date.new(year, month, 1) rescue nil
    end

    # 5. Month/2-digit Year format: MM/YY or MM-YY or MM.YY (e.g. 08/26 or 8/26)
    if str =~ %r{\A(\d{1,2})[/.-](\d{2})\z}
      month, short_year = $1.to_i, $2.to_i
      year = short_year + (short_year >= 70 ? 1900 : 2000)
      return Date.new(year, month, 1) rescue nil
    end

    # 6. Fallback using Date.strptime for DD/MM/YYYY before Date.parse
    Date.strptime(str, "%d/%m/%Y") rescue Date.parse(str) rescue nil
  rescue StandardError
    nil
  end

  def parse_date(val)
    self.class.parse_date(val)
  end

  def find_or_create_category(cat_name)
    name = cat_name.to_s.strip.presence || "Alimentação"
    @account.categories.find_by("LOWER(name) = ?", name.downcase) ||
      @account.categories.create!(name: name)
  end

  def find_or_create_supplier(sup_name)
    name = sup_name.to_s.strip.presence || "Geral"
    @account.suppliers.find_by("LOWER(name) = ?", name.downcase) ||
      @account.suppliers.create!(name: name)
  end

  def find_or_create_cost_center(cc_name)
    return nil if cc_name.blank?

    name = cc_name.to_s.strip
    @account.cost_centers.find_by("LOWER(name) = ?", name.downcase) ||
      @account.cost_centers.create!(name: name)
  end

  def find_or_create_bank_account(name)
    str = name.to_s.strip
    return nil if str.blank?

    @account.bank_accounts.find_by("LOWER(name) = ?", str.downcase) ||
      @account.bank_accounts.create!(name: str)
  end

  def find_or_create_credit_card(name, bank_acc = nil)
    str = name.to_s.strip
    return nil if str.blank?

    existing = @account.credit_cards.find_by("LOWER(name) = ?", str.downcase)
    return existing if existing.present?

    target_bank = bank_acc || @account.bank_accounts.first || @account.bank_accounts.create!(name: "Conta Principal")
    @account.credit_cards.create!(name: str, bank_account: target_bank, limit: 0)
  end

  def assign_payment_source(data, tx_type)
    bank_name = data[:bank_account].to_s.strip
    card_name = data[:credit_card].to_s.strip

    bank_acc = find_or_create_bank_account(bank_name) if bank_name.present?
    bank_acc ||= @account.bank_accounts.find_by(id: @bank_account_id) if @bank_account_id.present?

    card = find_or_create_credit_card(card_name, bank_acc) if card_name.present?
    card ||= @account.credit_cards.find_by(id: @credit_card_id) if @credit_card_id.present?

    if tx_type == "income"
      bank_acc ||= @account.bank_accounts.first || @account.bank_accounts.create!(name: "Conta Principal")
      { bank_account: bank_acc, credit_card: nil }
    elsif tx_type == "transfer"
      bank_acc ||= @account.bank_accounts.first || @account.bank_accounts.create!(name: "Conta Principal")
      { bank_account: bank_acc, credit_card: card }
    elsif card.present?
      { bank_account: nil, credit_card: card }
    else
      bank_acc ||= @account.bank_accounts.first || @account.bank_accounts.create!(name: "Conta Principal")
      { bank_account: bank_acc, credit_card: nil }
    end
  end
end
