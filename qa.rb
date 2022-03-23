require 'csv'
require 'time'
require 'date'
require 'YAML'
require 'JSON'
require 'colorize'

require_relative 'lib/validate_headers'
require_relative 'lib/data_validation'
require_relative 'lib/csv_writer'
require_relative 'lib/sheet'

filenames = Dir.glob(Dir.home + "/Downloads/*.csv")

mode = ARGV[0]
needs_fixing = false

files = 0

csv_writer = CsvWriter.new()
header_validator = ValidateHeaders.new()
data_validator = DataValidation.new()

filenames.each do |file|
  files += 1
  sheet = Sheet.new(file)

  if sheet.file_type == 'Unknown'
    puts "#{sheet.company_name} - #{sheet.customer_name} could not be validated due to the file's naming conventions (Sheet not named Frontend, Archive, Buyers).\n".yellow

    filename_split = file.split("/")
    filename_split[-1] = "*" + filename_split[-1]
    File.rename(file, filename_split.join('/'))

    next
  end

  # frontend
  if mode == '-a' || mode == '-o'
    csv_writer.add_file(sheet)
  end

  header_validator.call(sheet)
  data_validator.call(sheet)

  issues = header_validator.issues
  issues = data_validator.issues.merge(issues)

  unless issues.empty?
    puts "#{sheet.company_name} - #{sheet.customer_name} had the following issues:".red
    puts(JSON.pretty_generate(issues), "\n")

    filename_split = file.split("/")
    filename_split[-1] = "**" + filename_split[-1]
    File.rename(file, filename_split.join('/'))

    needs_fixing = true
  end
end

case needs_fixing
when true
  puts %Q[Some files reported a few issues. "**" has been added to filename of files with reported issues. #{files} files were checked.].yellow

  if mode == '-o'
    csv_writer.write_file()
  end
when false
  puts "Ready to import! #{files} files were checked.".green

  if mode == '-a'
    csv_writer.write_file()
  end
end
