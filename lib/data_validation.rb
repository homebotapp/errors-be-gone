require 'YAML'
require 'time'
require 'csv'

class DataValidation
  attr_reader :csv,
              :open_file,
              :company_name,
              :client_name,
              :valid_loan_terms,
              :issues,
              :valid_nmls_loan_types,
              :file_type,
              :headers,
              :yaml

  def initialize
  end

  def call(sheet)
    downcase_converter = lambda { |header| header.downcase }
    @open_file = CSV.parse(File.read(sheet.file), headers: true, header_converters:downcase_converter)
    @headers = open_file.headers.map(&:downcase)
    @company_name = sheet.company_name
    @customer_name = sheet.customer_name
    @file_type = sheet.file_type
    @issues = {}

    case @file_type
    when 'Archive'
      @yaml = YAML.load_file('yml/lo.yml')

      @open_file.headers.each do |column|
        if @yaml.include?(column)
          value_issues = parse_and_validate(column, @yaml[column]['parser'], @yaml[column]['present'])
          if value_issues.size > 0
            CSV.open("stats-for-nerds.csv", "a") do |csv|
              csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Archive', 'data_validation', column.to_s, value_issues]
            end

            if value_issues.length > 20
              value_issues = ["More than 20 issues found. Some examples are the following:", value_issues[0], value_issues[9], value_issues[-1]]
            end 

            @issues[column] = value_issues
          end
        end
      end

      unless sheet.multi
        if multiple_nmls_ids?
          CSV.open("stats-for-nerds.csv", "a") do |csv|
            csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Archive', 'data_validation', 'nmls loan originator id', ['multiple NMLS ids']]
          end

          @issues['nmls loan originator id'] = ['multiple nmls ids']
        end
      end

      if @open_file.headers.include?('subject property purchase date') && @open_file.headers.include?('closing date')
        value_issues = predateing_closing_dates(@open_file['subject property purchase date'], @open_file['closing date'])
        if value_issues.size > 0
          CSV.open("stats-for-nerds.csv", "a") do |csv|
            csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Archive', 'data_validation', 'closing date predating purchase date'.to_s, value_issues]
          end

          if value_issues.length > 20
            value_issues = ["More than 20 issues found. Some examples are the following:", value_issues[0], value_issues[9], value_issues[-1]]
          end 

          @issues['closing date predating purchase date'] = value_issues
        end
      end

    when 'Frontend'
      @yaml = YAML.load_file('yml/rea.yml')

      @open_file.headers.each do |column|
        if @yaml.include?(column)
          value_issues = parse_and_validate(column, @yaml[column]['parser'], @yaml[column]['present'])
          if value_issues.size > 0
            CSV.open("stats-for-nerds.csv", "a") do |csv|
              csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Frontend', 'data_validation', column.to_s, value_issues]
            end

            if value_issues.length > 20
              value_issues = ["More than 20 issues found. Some examples are the following:", value_issues[0], value_issues[9], value_issues[-1]]
            end 

            @issues[column] = value_issues
          end
        end
      end

    when 'Buyers'
      @yaml = YAML.load_file('yml/buyers.yml')

      @open_file.headers.each do |column|
        if @yaml.include?(column)
          value_issues = parse_and_validate(column, @yaml[column]['parser'], @yaml[column]['present'])
          if value_issues.size > 0
            CSV.open("stats-for-nerds.csv", "a") do |csv|
              csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Buyers', 'data_validation', column.to_s, value_issues]
            end

            if value_issues.length > 20
             value_issues = ["More than 20 issues found. Some examples are the following:", value_issues[0], value_issues[9], value_issues[-1]]
            end 

            @issues[column] = value_issues
          end
        end
      end

    end
  end

  def multiple_nmls_ids?
    @open_file['nmls loan originator id'].uniq.size > 1
  end

  def predateing_closing_dates(purchase_date_column, closing_date_column)
    invalid_values = []
    row_number = 1

    combined = purchase_date_column.zip(closing_date_column).each do |pairs|
      row_number += 1

      purchase_date = Date.strptime(pairs[0], '%m/%d/%Y') rescue nil
      closing_date = Date.strptime(pairs[1], '%m/%d/%Y') rescue nil

      if purchase_date != nil && closing_date != nil && (purchase_date - 45) > closing_date
        invalid_values.push("Purchase Date: #{pairs[0]} Closing Date: #{pairs[1]} (row #{row_number})")
        #invalid_values.push("At least one issue found. Check if Purchase Date is 45 days past Closing Date.")
        break
      end
    end

    invalid_values
  end

  def parse_and_validate(column_name, data_type, present)
    invalid_values = []
    row_number = 1

    @open_file[column_name].each do |value|
      row_number += 1
      if value.nil? || value == " "
        if present
          invalid_values.push("blank (row #{row_number})")
        end
      elsif valid?(value, data_type) == false
        invalid_values.push(value.to_s + " (row #{row_number})")
      end
    end

    # if invalid_values.length > 20
    #   ["More than 20 issues found. Some examples are the following:", invalid_values[0], invalid_values[9], invalid_values[19]]
    # else
    #   invalid_values
    # end

    invalid_values
  end

  def valid?(val, validation_type)
    return true if validation_type.nil?

    val_s = val.to_s.strip

    case validation_type
    when 'is_string'
      val_s.scan(/\d/).empty?

    when 'is_date'
      Date.strptime(val_s, '%m/%d/%Y') && true rescue false

    when 'is_decimal'
      val_s.match?(/\A\d*\.?\d*\z/)

    when 'is_integer'
      val_s.match?(/\d+/) &&
      !val_s.include?('$')

    when 'is_property_value'
      val_s.match?(/\d+/) &&
      (val_s.delete(',').to_i > 10000 || val_s.delete(',').to_i == 0) &&
      !val_s.include?('$')

    when 'is_gender'
      val_s.match?(/\AMale|Female\z/)

    when 'is_email'
      val_s.match?(/[\w-]+@([\w-]+\.)+[\w-]+/) &&
        !val_s.match?(/\A(none|noemail|fakeemail|na)@/)

    when 'is_address'
      # return false if val_s.match?(/(;|&|\+|(\s+and\s+))+/)
      val_s.match?(/(\d)+(-?)[a-zA-Z]?\s+([a-zA-Z0-9])+/)

    when 'is_zipcode'
      val_s.match?(/^[0-9]{5}$/)

    when 'is_interest_rate'
      val_s.match?(/\A\d*\.?\d*\z/) &&
      val_s.to_f >= 0 &&
      val_s.to_f < 13

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
      # issue
      (now - past < 100) rescue false

    when 'is_loan_term'
      val_s.match?(/\d+/) && %w[360 300 264 240 180 120].include?(val_s)

    when 'is_locale'
      %w[en es spanish english].include?(val_s.downcase)

    when 'is_boolean'
      %w[true false].include?(val_s.downcase)

    when 'is_buyers_value'
      !%w[. ,].include?(val_s)

    else
      false
    end
  end

end
