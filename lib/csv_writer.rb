class CsvWriter
  attr_accessor :indv_output,
                :multi_output,
                :addl_output,
                :number_of_files,
                :total_rows,
                :nmls_ids,
                :duplicate_customer

  def initialize
    @number_of_files = 0
    @total_rows = 0
    @indv_output = Array.new()
    @multi_output = Array.new()
    @addl_output = Array.new()
    @nmls_ids = Array.new()
    @indv_nmls_ids = Array.new()
    @multi_nmls_ids = Array.new()
    @duplicate_customer = Array.new()
  end

  def add_file(sheet)
    @number_of_files +=1
    @total_rows += sheet.rows

    @nmls_ids.push(sheet.nmls_ids)

    if sheet.multi
      @multi_nmls_ids.push(sheet.nmls_ids)

      if sheet.is_update?
        @multi_output.push("#{sheet.company_name} - #{sheet.update_name} _#{sheet.rows} rows_\n")
      else
        @multi_output.push("#{sheet.company_name} _#{sheet.rows} rows_\n")
      end
    else
      if @indv_nmls_ids.include?(sheet.nmls_ids)
        duplicate_customer.push(sheet.customer_name)
      end

      @indv_nmls_ids.push(sheet.nmls_ids)

      if sheet.is_update?
        if sheet.addl_file
          @addl_output.push("#{sheet.company_name} - #{sheet.customer_name} - Update _#{sheet.rows} rows_\n")
        else
          @indv_output.push("#{sheet.company_name} - #{sheet.customer_name} - Update _#{sheet.rows} rows_\n")
        end
      else
        if sheet.addl_file
          @addl_output.push("#{sheet.company_name} - #{sheet.customer_name} _#{sheet.rows} rows_\n")
        else
          @indv_output.push("#{sheet.company_name} - #{sheet.customer_name} _#{sheet.rows} rows_\n")
        end
      end
    end
  end

  def write_file()
    output = File.new("../" + create_name, 'a')
    output.puts("@data_team Imported to Archive:\n")

    unless @indv_output.empty?
      output.puts(@indv_output.sort)
    end

    unless @addl_output.empty?
      output.puts("\nArchive/Frontend/Buyers (Move to “past imports via archive” after importing frontend/buyers tab):\n")
      output.puts(@addl_output.sort)
    end

    unless @multi_output.empty?
      output.puts("\nMultiple NMLS IDs:\n")
      output.puts(@multi_output.sort)
    end

    output.puts("\nAll NMLS IDs:\n", @nmls_ids.join("")[0..-2])
    output.puts("\nIndividual NMLS IDs:\n", @indv_nmls_ids.join("")[0..-2])
    output.puts("\n", "#{@total_rows} | #{@indv_nmls_ids.uniq.size} files")

    unless duplicate_customer.empty?
      output.puts("\n", "#{duplicate_customer.uniq.join(", ")} has/have multiple files. You should have #{@indv_nmls_ids.uniq.size} unique customers.")
    end

    output.close
  end

  def create_name
    time = Time.new
    time.strftime("%m%d%Y_%k%M") + ".txt"
  end

end
