require "firebase"
require "json"
require "fileutils"

require "./firebase_cred"

firebase = Firebase::Client.new(BASE_URI)

# Save institutes in firebase locally in json files
response = firebase.get("institutions")

institutions = response.body.values

dir_name = "backup_#{Time.now.to_s}"
FileUtils::mkdir_p dir_name

counter = 0
institutions.each do |institution|
	File.open("#{dir_name}/#{counter}.json", "w") { |file|
		file.write(institution.to_json)
	}
	counter += 1
end