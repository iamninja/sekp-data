require "firebase"
require "json"
require "fileutils"

require "./firebase_cred.rb"

JSON_PATH = 'data/json'

firebase = Firebase::Client.new(BASE_URI)

# Remove any old entries in database
firebase.set("institutions", {})

# Iterate through json fiels and upload each of
# them as an entry to firebase
Dir.foreach(JSON_PATH) do |jsonfile|
	next if jsonfile == '.' or jsonfile =='..'

	File.open("#{JSON_PATH}/#{jsonfile}") { |file|
		data = JSON.parse(file.readlines[0])
		firebase.push("institutions", data)
		# Log the name if jsonfile has missing values
		if data.length < 8
			puts jsonfile + "(#{data["name"]})" + "Total values: (#{data.length})"
		end
	}
end