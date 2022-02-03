class Sheet
  attr_accessor :company_name, :customer_name, :rows, :nmls_ids, :file_type, :update_name, :multi, :addl_file, :file

  def initialize(file)
    @file = file
    @company_name = get_company_name()
    @customer_name = get_customer_name()
    @rows = get_number_of_rows()
    @file_type = get_file_type()
    @update_name = get_update_name()
    @multi = multiple_los?()
    @nmls_ids = []
    get_nmls_ids()
    @addl_file = additional_file?()
  end

  def additional_file?()
    @file.split('-').any? { |s| s.include?('Archive') && (s.include?('Frontend') || s.include?('Buyers'))}
  end

  def get_nmls_ids()
    if @file_type == 'Archive'
      open_file = CSV.parse(File.read(@file), headers: true)

      unless open_file.headers.include?('NMLS Loan Originator ID')
        @nmls_ids = 'error'
      else
        if @multi
          open_file['NMLS Loan Originator ID'].uniq.each do |id|
            @nmls_ids.push("'#{id}',")
          end
        else
          @nmls_ids.push("'#{open_file[0]['NMLS Loan Originator ID']}',")
        end
      end
    end
  end

  def get_number_of_rows()
    CSV.parse(File.read(@file), headers: true).length
  end

  def get_company_name()
    @file.split('-')[1].split(/(?<=\p{Ll})(?=\p{Lu})|(?<=\p{Lu})(?=\p{Lu}\p{Ll})/).join(' ')
  end

  def get_customer_name()
    @file.split('-')[2].split(/(?<=\p{Ll})(?=\p{Lu})|(?<=\p{Lu})(?=\p{Lu}\p{Ll})/).join(' ')
  end

  def is_update?()
    @file.split('-').any? { |s| s.include?('Update')}
  end

  def get_update_name()
    split_title = @file.split('-')
    name = split_title.detect {|e| e.include?('Update')}
    name
  end

  def get_file_type()
    sheet_name = @file.split('-')[-1].downcase

    if sheet_name.include?('archive')
      'Archive'
    elsif sheet_name.include?('frontend')
      'Frontend'
    elsif sheet_name.include?('buyers')
      'Buyers'
    else
      'Unknown'
    end
  end

  def multiple_los?()
    @file.downcase.split('-').any? { |s| s.include?('multiplelos')}
  end
end
