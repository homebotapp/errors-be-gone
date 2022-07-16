class ValidateHeaders
  attr_reader :company_name,
              :customer_name,
              :headers,
              :all_headers,
              :issue,
              :required_headers_archive,
              :required_headers_frontend,
              :required_headers_buyers,
              :file_type,
              :issues

  def initialize
    @all_headers = ['Borrower First/Middle Name',
                    'Borrower Last Name/Suffix',
                    'Borr Cell Phone',
                    'Borr Email',
                    'Borr Marital Status',
                    'Borr Dependent #',
                    'Borr Dependent Ages',
                    'Borr Sex Male/Female',
                    'Borr DOB',
                    'Income Borr Total Income',
                    'Borr Language Preference',
                    'Co-Borrower First/Middle Name',
                    'Co-Borrower Last Name/Suffix',
                    'Co-Borr Cell Phone',
                    'Co-Borr Email',
                    'Co-Borr Marital Status',
                    'Co-Borr # Dependents',
                    'Co-Borr Dependents Ages',
                    'Co-Borr DOB',
                    'Co-Borr Sex Male/Female',
                    'Income Co-Borr Total Income',
                    'Co-Borr Language Preference',
                    'Subject Property Address',
                    'Subject Property Zip',
                    'Subject Property Appraised Value',
                    'Subject Property Appraised Date',
                    'Subject Property Purchase Price',
                    'Subject Property Purchase Date',
                    'Original Cost',
                    'Year Acquired',
                    'HOA Dues',
                    'Expenses Proposed Total Housing',
                    'Fees Flood Ins Per Mo',
                    'Hazard Insurance Company Name',
                    'Expenses Proposed Haz Ins',
                    'Occupancy (PSI)',
                    'Parcel#',
                    'Title Insurance Company Name',
                    'Real Estate Broker B Name',
                    'Real Estate Broker B Address',
                    'Real Estate Broker B Zip',
                    'Real Estate Broker B State License',
                    'Real Estate Broker B Contact',
                    'Real Estate Broker B Contact State License',
                    'Real Estate Broker B Contact Email',
                    'Real Estate Broker B Contact Office Phone',
                    'Total Loan Amount',
                    'Interest Rate',
                    'Loan Term',
                    'Loan Purpose',
                    'Closing Date',
                    'NMLS Loan Originator ID',
                    'Lender NMLS ID',
                    'NMLS Loan Type',
                    'First Payment Due Date',
                    'Refi Purpose',
                    'Refinance Type',
                    'Lien Position',
                    'Amort Type',
                    'Total Monthly Payment',
                    'Mortgage Insurance Premium',
                    'APR',
                    'ARM Index',
                    'Arm Rate Cap',
                    'ARM First Period Change',
                    'ARM Margin',
                    'ARM Life Cap',
                    'First Rate Adjustment Cap',
                    'List of Loan Special Programs',
                    'DPA Grant Program',
                    'Loan Type',
                    'Insurance MTG Ins Upfront Factor',
                    'Loan Number',
                    'Lender Case #',
                    'HUD Escrow Monthly Payment',
                    'FHA Anticipated Premium Due',]
    @all_headers_buyers = ['First Name',
                    'Last Name',
                    'Email',
                    'Phone',
                    'Zip Codes',
                    'Price Point',
                    'Language Preference',
                    'Max Loan Amount',
                    'Downpayment',
                    'Max Home Price',
                    'Estimated Rate',
                    'Loan Type',
                    'Loan Term Months',
                    'Loan Adjustable',
                    'Loan ARM Years Initial',
                    'Expires At',
                    'Preapproved']
    @required_headers_archive = ['Borrower First/Middle Name',
                    'Borrower Last Name/Suffix',
                    'Borr Email',
                    'Subject Property Address',
                    'Subject Property Zip',
                    'Total Loan Amount',
                    'Interest Rate',
                    'Loan Term',
                    'Loan Purpose',
                    'Closing Date',
                    'NMLS Loan Originator ID',
                    'Lender NMLS ID',
                    'NMLS Loan Type']
    @required_headers_frontend = ['Borrower First/Middle Name',
                    'Borrower Last Name/Suffix',
                    'Borr Email',
                    'Subject Property Address',
                    'Subject Property Zip',]
    @required_headers_buyers = ['First Name',
                    'Last Name',
                    'Email']
  end

  def call(sheet)
    open_file = CSV.parse(File.read(sheet.file), headers: true)
    @headers = open_file.headers.map(&:downcase)
    @company_name = sheet.company_name
    @customer_name = sheet.customer_name
    @file_type = sheet.file_type
    @issues = {}

    case @file_type
    when 'Archive'
      if duplicate_headers?
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Archive', 'header_validation', 'duplicate_headers', duplicate_headers.map(&:capitalize).uniq]
        end

        @issues['Duplicate Headers'] = duplicate_headers.map(&:capitalize).uniq
      end

      if missing_required?
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Archive', 'header_validation', 'missing_required_headers', missing_required.map(&:capitalize)]
        end

        @issues['Missing Required Headers'] = missing_required.map(&:capitalize)
      end

      if sheet.nmls_ids == 'error'
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Archive', 'header_validation', 'nmls_origintor_syntax']
        end

        @issues['NMLS Originator ID Missing or Incorrectly Capatilzied'] = true
      end

      unless valid_headers?
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Archive', 'header_validation', 'invalid_headers', valid_headers.map(&:capitalize)]
        end

        @issues['Invalid Headers'] = valid_headers.map(&:capitalize)
      end

    when 'Frontend'
      if duplicate_headers?
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Frontend', 'header_validation', 'duplicate_headers', duplicate_headers.map(&:capitalize).uniq]
        end

        @issues['Duplicate Headers'] = duplicate_headers.map(&:capitalize).uniq
      end

      if missing_required?
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Frontend', 'header_validation', 'missing_required_headers', missing_required.map(&:capitalize)]
        end

        @issues['Missing Required Headers'] = missing_required.map(&:capitalize)
      end

      unless valid_headers?
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Frontend', 'header_validation', 'valid_headers', valid_headers.map(&:capitalize)]
        end

        @issues['Invalid Headers'] = valid_headers.map(&:capitalize)
      end

    when 'Buyers'
      if duplicate_headers?
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Frontend', 'header_validation', 'duplicate_headers', duplicate_headers.map(&:capitalize).uniq]
        end

        @issues['Duplicate Headers'] = duplicate_headers.map(&:capitalize).uniq
      end

      if missing_required?
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Buyers', 'header_validation', 'missing_required_headers', missing_required.map(&:capitalize)]
        end

        @issues['Missing Required Headers'] = missing_required.map(&:capitalize)
      end

      unless valid_headers?
        CSV.open("stats-for-nerds.csv", "a") do |csv|
          csv << [sheet.file.split('/')[-1], Time.now.to_s, 'Buyers', 'header_validation', 'valid_headers', valid_headers.map(&:capitalize)]
        end

        @issues['Invalid Headers'] = valid_headers.map(&:capitalize)
      end

    end

  end

  def duplicate_headers
    @headers.find_all { |e| @headers.rindex(e) != @headers.index(e)}.uniq
  end

  def duplicate_headers?
    @headers.length != @headers.uniq.length
  end

  def missing_required
    case @file_type
    when 'Archive'
      @required_headers_archive.map(&:downcase) - @headers
    when 'Frontend'
      @required_headers_frontend.map(&:downcase) - @headers
    when 'Buyers'
      @required_headers_buyers.map(&:downcase) - @headers
    end
  end

  def missing_required?
    missing_required.size > 0
  end

  def valid_headers
    invalid_headers = []

    if @file_type == 'Buyers'
      invalid_headers = @headers - @all_headers_buyers.map(&:downcase)
    else
      invalid_headers = @headers - @all_headers.map(&:downcase)
    end

    if @headers.include?(nil)
      invalid_headers.push('blank(s)')
    end

    invalid_headers
  end

  def valid_headers?
    valid_headers.empty?
  end
end
