require 'csv'

class ImportFromSpreadsheet
  def self.run!
    new.run!
  end

  def run!
    csv_data = RestClient.get(csv_uri)

    CSV.parse(csv_data, {
      headers: true,
      converters: :all
    }) do |row|
      name        = row[0].strip
      company     = row[1].strip
      email       = row[2].strip
      invited_by  = row[3].strip

      unless Guest.exist?(email: email)
        Guest.create name: name, company: company, email: email, invited_by: invited_by
      end
    end
  end

  def get_data

  end

  def csv_uri
    'https://docs.google.com/spreadsheet/pub?key=' +
    '0At7V3H8zJRWTdG5leEhlNFBwRlM3VUEteGxRNWFLcWc' +
    '&single=true&gid=4&output=csv'
  end
end
