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
    cost_center: [ "centro_de_custo", "cost_center", "centro de custo", "centro de custo" ]
  }.freeze

  def initialize(file_path:, filename:, account:, bank_account_id: nil, credit_card_id: nil)
    @file_path = file_path
    @filename = filename
    @account = account
    @bank_account_id = bank_account_id.presence
    @credit_card_id = credit_card_id.presence
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
      Roo::CSV.new(@file_path)
    when ".xlsx"
      Roo::Excelx.new(@file_path)
    when ".xls"
      Roo::Excel.new(@file_path)
    else
      nil
    end
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

    payment_attrs = assign_payment_source(tx_type)

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

  def assign_payment_source(tx_type)
    bank_acc = @account.bank_accounts.find_by(id: @bank_account_id) if @bank_account_id.present?
    card = @account.credit_cards.find_by(id: @credit_card_id) if @credit_card_id.present?

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
