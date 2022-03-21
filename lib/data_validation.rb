class DataValidation
  attr_reader :csv,
              :open_file,
              :company_name,
              :client_name,
              :valid_loan_terms,
              :issue,
              :valid_nmls_loan_types,
              :file_type,
              :headers,
              :issue

  def initialize
  end

  def call(sheet)
    downcase_converter = lambda { |header| header.downcase }
    @open_file = CSV.parse(File.read(sheet.file), headers: true, header_converters:downcase_converter)
    @headers = open_file.headers.map(&:downcase)
    @company_name = sheet.company_name
    @customer_name = sheet.customer_name
    @file_type = sheet.file_type
    @issue = false

    case @file_type
    when 'Archive'
      if property_valuation_columns?
        puts "[#{@company_name} - #{@customer_name}] has dates in one of the valuation columns."
        @issue = true
      end

      if parse_and_validate('closing date', 'is_date').size > 0
        puts "[#{@company_name} - #{@customer_name}] has an invalid closing date(s): #{parse_and_validate('closing date', 'is_date').join(", ")}"
        @issue = true
      end

      if parse_and_validate('borr dob', 'is_birthday')
        puts "[#{@company_name} - #{@customer_name}] has an invalid birth date(s): #{parse_and_validate('borr dob', 'is_birthday').join(", ")}"
        @issue = true
      end

      if parse_and_validate('borr email', 'is_email')
        puts "[#{@company_name} - #{@customer_name}] has an invalid email(s): #{parse_and_validate('borr email', 'is_email').join(", ")}"
        @issue = true
      end

      if parse_and_validate('co-borr email', 'is_email')
        puts "[#{@company_name} - #{@customer_name}] has an invalid email(s): #{parse_and_validate('co-borr email', 'is_email').join(", ")}"
        @issue = true
      end

      if parse_and_validate('co-borr dob', 'is_birthday')
        puts "[#{@company_name} - #{@customer_name}] has an invalid birth date(s): #{parse_and_validate('co-borr dob', 'is_birthday').join(", ")}"
        @issue = true
      end

      if parse_and_validate('loan term', 'is_loan_term').size > 0
        puts "[#{@company_name} - #{@customer_name}] has an invalid loan term(s): #{parse_and_validate('loan term', 'is_loan_term').join(", ")}"
        @issue = true
      end

      if parse_and_validate('nmls loan type', 'is_nmls_loan_type').size > 0 && parse_and_validate('nmls loan type', 'is_nmls_loan_type').size <= 10
        puts "[#{@company_name} - #{@customer_name}] has an invalid nmls loan type(s): #{parse_and_validate('nmls loan type', 'is_nmls_loan_type').join(", ")}"
        @issue = true
      elsif parse_and_validate('nmls loan type', 'is_nmls_loan_type').size > 10
        puts "[#{@company_name} - #{@customer_name}] has >5 invalid nmls loan types, check that column."
        @issue = true
      end

      if blank_nmls_ids?
        puts "[#{@company_name} - #{@customer_name}] has blank NMLS IDs."
        @issue = true
      end

      unless sheet.multi
        if multiple_nmls_ids?
          puts "[#{@company_name} - #{@customer_name}] has multiple NMLS IDs in their file."
          @issue = true
        end
      end

    when 'Frontend'
      if property_valuation_columns?
        puts "[#{@company_name} - #{@customer_name}] has dates in one of the valuation columns."
        @issue = true
      end

      if parse_and_validate('borr dob', 'is_birthday')
        puts "[#{@company_name} - #{@customer_name}] has an invalid birth date(s): #{parse_and_validate('borr dob', 'is_birthday').join(", ")}"
        @issue = true
      end

      if parse_and_validate('borr email', 'is_email')
        puts "[#{@company_name} - #{@customer_name}] has an invalid email(s): #{parse_and_validate('borr email', 'is_email').join(", ")}"
        @issue = true
      end

      if parse_and_validate('co-borr email', 'is_email')
        puts "[#{@company_name} - #{@customer_name}] has an invalid email(s): #{parse_and_validate('co-borr email', 'is_email').join(", ")}"
        @issue = true
      end

      if parse_and_validate('co-borr dob', 'is_birthday')
        puts "[#{@company_name} - #{@customer_name}] has an invalid birth date(s): #{parse_and_validate('co-borr dob', 'is_birthday').join(", ")}"
        @issue = true
      end
    when 'Buyers'

    end
  end

  def multiple_nmls_ids?
    @open_file['nmls loan originator id'].uniq.size > 1
  end

  def property_valuation_columns?
    purchase_price_column = @open_file['subject property purchase price']
    appraised_value_column = @open_file['subject property appraised value']

    if purchase_price_values?(purchase_price_column) || appraised_price_values?(appraised_value_column)
      true
    else
      false
    end
  end

  def purchase_price_values?(column)
    result = false
    column.each do |value|
      if valid?(value, 'is_date')
        result = true
        break
      end
    end
    result
  end

  def appraised_price_values?(column)
    result = false
    column.each do |value|
      if valid?(value, 'is_date')
        result = true
        break
      end
    end
    result
  end

  def parse_and_validate(column_name, data_type)
    invalid_values = []
    row_number = 1
    @open_file[column_name].each do |value|
      row_number += 1
      if value.nil?
        invalid_values.push("Blank (row #{row_number})")
      elsif valid?(value, data_type) == false
        invalid_values.push(value + "(row #{row_number})")
      end
    end
    invalid_values
  end

  def blank_nmls_ids?
    @open_file['nmls loan originator id'].include?(nil)
  end

  def valid?(val, validation_type)
    return true if validation_type.nil?

    val_s = val.to_s.strip

    case validation_type
    when 'is_date'
      Date.strptime(val_s, '%m/%d/%Y') && true rescue false

    when 'is_decimal'
      val_s.match?(/\A\d*\.?\d*\z/)\

    when 'is_integer'
      val_s.match?(/\d+/)

    when 'is_gender'
      val_s.match?(/\Am|f\z/)

    when 'is_email'
      val_s.match?(/[\w-]+@([\w-]+\.)+[\w-]+/) &&
        !val_s.match?(/\A(none|noemail|fakeemail)@/)

    when 'is_address'
      return false if val_s.match?(/(;|&|\+|(\s+and\s+))+/)
      val_s.match?(/(\d)+(-?)[a-zA-Z]?\s+([a-zA-Z0-9])+/)

    when 'is_zipcode'
      val_s.match?(/^[0-9]{5}$/)

    when 'is_interest_rate'
      val_s.match?(/^\d*\.{1}\d*$/)

    when 'is_phone'
      val_s.match?(/\A(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}/)

    when 'is_nmls_loan_type'
      %w[ResidentialFirst Second HELOC Reverse Construction].include?(val_s)

    when 'is_birthday'
      begin
        past = Date.strptime(val_s, "%m/%d/%Y").year
      rescue
      end
      now = Date.today.year
      (now - past < 100) rescue false

    when 'is_loan_term'
      val_s.match?(/\d+/) && %w[360 300 264 240 180 120].include?(val_s)

    when 'is_locale'
      %w[en es spanish english].include?(val_s.downcase)

    when 'is_boolean'
      %w[true false].include?(val_s.downcase)

    else
      false
    end
  end

end
