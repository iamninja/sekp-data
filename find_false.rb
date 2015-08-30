require "firebase"
require "json"
require "fileutils"
require "open-uri"

require "./firebase_cred"

firebase = Firebase::Client.new(BASE_URI)

# Save institutes in firebase locally in json files
response = firebase.get("institutions")

institutions = response.body.values

puts "---------------- Empty 'areas' ----------------"
institutions.each do |institution|
	if institution["areas"] == ""
		puts institution["name"]
	end
end

puts "---------------- Invalid URLs ----------------"
institutions.each do |institution|
	if institution["website"] =! "" and (institution["website"] =~ URI::regexp(["http", "https"]))
		puts institution["name"]
	end
end

puts "---------------- Empty names ----------------"
hash = response.body
hash.each do |id, institution|
	if institution["name"] == ""
		puts id
	end
end