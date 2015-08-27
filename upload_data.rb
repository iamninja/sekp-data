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
		firebase.push("institutions", JSON.parse(file.readlines[0]))
	}
end