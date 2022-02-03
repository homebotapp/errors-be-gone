require 'csv'
require 'time'
require 'date'

require_relative 'lib/validate_headers'
require_relative 'lib/data_validation'
require_relative 'lib/csv_writer'
require_relative 'lib/sheet'

filenames = Dir.glob("../*.csv")

mode = ARGV[0]

csv_writer = CsvWriter.new()
header_validator = ValidateHeaders.new()
data_validator = DataValidation.new()

filenames.each do |file|
  sheet = Sheet.new(file)

  if sheet.file_type == 'Unknown'
    puts("#{sheet.company_name} - #{sheet.customer_name} could not be validated due to the file's naming conventions.")
    next
  end

  # frontend
  if mode == '-a' && sheet.file_type == 'Archive'
    csv_writer.add_file(sheet)
  end

  header_validator.call(sheet)
  data_validator.call(sheet)

  if header_validator.issue == true || data_validator.issue == true
     File.rename(file, "../**"+file.split('/')[1])
  end
end

if mode == '-a'
  csv_writer.write_file()
end