require 'rubygems'
require 'nokogiri'
require 'kristin'
require 'fileutils'
require 'json'

PDF_FILE = 'raw/kp_foreis.pdf'
HTML_FILE = 'data/kp_foreis.html'
TXT_FILE = 'data/text.txt'
JSON_PATH = 'data/json'
TXT_PATH = 'data/txt-files'

# Check and clean directories
def bootstrap_dir(dir)
	if File.directory? dir
		FileUtils.rm_rf("#{dir}/.", secure: true)
	else
		FileUtils::mkdir_p dir
	end
end

bootstrap_dir(JSON_PATH)
bootstrap_dir(TXT_PATH)

# Keys for institution hash
keys = ["name", "status", "year", "website", "description", "powers", "areas"]

# pdf2htmlex/Kristin options
opts = {
	first_page: 11,
	last_page: 30
}

number_of_pages = opts[:last_page] - opts[:first_page]


# Generate the html file with pdf2htmlex
puts "Generating html file from pdf"
Kristin.convert(PDF_FILE, HTML_FILE, opts)
print "\rDone\n"

@html = Nokogiri::HTML(File.open(HTML_FILE))

@html.css('span').each do |span|
	span.swap(span.children.text.gsub("  ", " ").gsub("\n", " ").gsub("\s", " "))
end

# Create text file with all data
print "Generating txt file from html."
File.open(TXT_FILE, "w") { |file|
	@html.css('div.pf').each do |organization|
		# file.puts (organization.text.gsub('  ', "\n").gsub('-', '').sub('(', "\n").sub(')', ''))
		file.puts (organization.text.gsub('  ', "\n").gsub('-', ''))
	end
}
puts " Done"

# Create a text file per institution
puts "Generating txt files. One per institution"
File.open(TXT_FILE, "r") { |file|
	institution_counter = 0
	counter = 0
	file.each_line do |line|
		print "\r#{institution_counter}"
		if (line == "\n")
			counter = 0
			institution_counter += 1
			next
		end
		if (counter < 8)
			counter += 1
			File.open("#{TXT_PATH}/#{institution_counter}.txt", "a") { |institution_file|
				institution_file.puts line
			}
		end

	end
}
puts "\nDone"

# Create json files from text files
puts "Generating json files from txt files."
json_file_counter = 0
Dir.foreach(TXT_PATH) do |txtfile|
	next if txtfile == '.' or txtfile == '..'
	size = 0
	newfirst = ""
	double_line_name = false
	File.open("#{TXT_PATH}/#{txtfile}", "r") { |file|
		size = file.readlines.size
	}
	# Skip files with less than 3 lines
	next if size < 3
	json_file_counter += 1

	# Debug
	# File.open("#{TXT_PATH}/#{txtfile}", "r") { |file|
	# 	puts "Printing contents of #{File.basename(file)}"
	# 	file.each_line do |line|
	# 		puts line
	# 	end
	# 	puts "End Printing"
	# }



	# Reopen the txtfile to read the data
	File.open("#{TXT_PATH}/#{txtfile}", "r") { |file|
		counter = 0
		clean_line = Array.new
		name_array = Array.new
		hash = Hash.new

		filename = File.basename(file, ".*")

		# Scan lines and create hash with institution's data
		file.each_line do |line|
			if (line.include? ':')
				value = clean_line.join(" ").gsub("\n", "")
				if (value.include? ':')
					value = value.slice(value.index(":")..-1).gsub(":", "").strip
				end
				hash[:"#{keys[counter]}"] = value
				clean_line.clear
				clean_line.push(line)
				counter += 1
			elsif (file.eof?)
				clean_line.push(line)
				value = clean_line.join(" ").gsub("\n", "")
				if (value.include? ':')
					value = value.slice(value.index(":")..-1).gsub(":", "").strip
				end
				hash[:"#{keys[counter]}"] = value
			else
				clean_line.push(line)
			end
		end

		# Get short short name if it exists
		if hash[:name].include? "("
			name_array = hash[:name].gsub("(", "@").gsub(")", "").partition("@").collect{ |item| item.strip }
			hash[:name] = name_array.first
			hash[:short] = name_array.last
		else
			hash[:short] = ""
		end

		# :areas values tend to have a trailing number. Clean it and trim
		if hash.key?(:areas)
			# puts "yep"
			hash[:areas] = hash[:areas].gsub(/\d+$/, "").strip
		end

		# Write json file for institution
		File.open("data/json/#{filename}.json", "w") { |json_file|
			print "\r#{json_file_counter}"
			json_file.write(hash.to_json)
		}
	}
end
puts "\nDone"
