require 'csv'

class ImportFromSpreadsheet
  def self.run!
    new.run!
  end

  def run!
    csv_data     = RestClient.get(csv_uri)
    import_count = 0

    CSV.parse(csv_data, {
      headers: true,
      converters: :all
    }) do |row|

      if !row.nil? && !row[0].nil? && !row[1].nil? && !row[2].nil? && !row[3].nil?
        name        = row[0].strip
        company     = row[1].strip
        email       = row[2].strip
        invited_by  = row[3].strip

        unless Guest.exist?(email: email)
          Guest.create name: name, company: company, email: email, invited_by: invited_by
          import_count += 1
        end
      end
    end

    import_count
  end

  def csv_uri
    'https://docs.google.com/spreadsheet/pub?key=' +
    '0At7V3H8zJRWTdG5leEhlNFBwRlM3VUEteGxRNWFLcWc' +
    '&single=true&gid=4&output=csv'
  end
end
