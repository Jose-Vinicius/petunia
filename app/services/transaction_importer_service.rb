require "roo"

class TransactionImporterService
  Result = Struct.new(:success_count, :error_count, :errors, keyword_init: true)

  HEADER_MAP = {
    date: [ "data", "date", "dt", "data transacao", "data transação" ],
    description: [ "descrição", "descricao", "description", "historico", "histórico", "detalhe", "memorando" ],
    amount: [ "valor", "amount", "val", "quantia" ],
    type: [ "tipo", "type", "natureza", "operacao", "operação" ],
    category: [ "categoria", "category" ],
    supplier: [ "fornecedor", "cliente", "supplier", "payee", "local", "estabelecimentos" ],
    cost_center: [ "centro_de_custo", "cost_center", "centro de custo", "centro de custo" ],
    bank_account: [ "banco", "bank", "bank_account", "conta", "conta bancaria", "conta bancária", "conta_bancaria" ],
    credit_card: [ "cartao", "cartão", "credit_card", "cartao_de_credito", "cartão de crédito", "cartao de credito", "cartao_credito" ]
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

      preview_rows << {
        date: parsed_date.strftime("%Y-%m-%d"),
        description: description,
        amount: raw_amount,
        transaction_type: tx_type,
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
      transaction = @account.transactions.build(transaction_attributes)

      if transaction.save
        success_count += 1
      else
        error_count += 1
        errors << "Linha #{index + 2}: #{transaction.errors.full_messages.join(', ')}"
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
      col_name = cell.to_s.strip.downcase
      HEADER_MAP.find { |_key, aliases| aliases.include?(col_name) }&.first || col_name.to_sym
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

    {
      transaction_type: tx_type,
      amount: raw_amount,
      description: description,
      date: parsed_date,
      category: category,
      supplier: supplier,
      cost_center: cost_center
    }.merge(payment_attrs)
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
    return "expense" if is_negative

    type_str = type_val.to_s.strip.downcase
    if type_str =~ /(despesa|saida|saída|expense|debito|débito)/
      "expense"
    else
      "income"
    end
  end

  def parse_date(val)
    return nil if val.blank?
    return val if val.is_a?(Date) || val.is_a?(Time) || val.is_a?(DateTime)

    str = val.to_s.strip
    if str =~ %r{\A\d{1,2}/\d{1,2}/\d{4}\z}
      Date.strptime(str, "%d/%m/%Y")
    elsif str =~ %r{\A\d{4}-\d{2}-\d{2}\z}
      Date.parse(str)
    else
      Date.parse(str)
    end
  rescue ArgumentError
    nil
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

  def assign_payment_source(data, tx_type)
    bank_name = data[:bank_account].to_s.strip
    card_name = data[:credit_card].to_s.strip

    bank_acc = @account.bank_accounts.find_by("LOWER(name) = ?", bank_name.downcase) if bank_name.present?
    bank_acc ||= @account.bank_accounts.find_by(id: @bank_account_id) if @bank_account_id.present?

    card = @account.credit_cards.find_by("LOWER(name) = ?", card_name.downcase) if card_name.present?
    card ||= @account.credit_cards.find_by(id: @credit_card_id) if @credit_card_id.present?

    bank_acc ||= @account.bank_accounts.first

    if tx_type == "income"
      { bank_account: bank_acc, credit_card: nil }
    elsif card.present?
      { bank_account: nil, credit_card: card }
    else
      { bank_account: bank_acc, credit_card: nil }
    end
  end
end
