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

# Categories
categories_array = [
	[{
		:id => 1,
		:name => "Κοινωνική Ασφάλιση"
	},
	{
		first_page: 11,
		last_page: 32
	}],
	[{
		:id => 2,
		:name => "Κοινωνική Πρόνοια"
	},
	{
		first_page: 35,
		last_page: 51
	}],
	[{
		:id => 3,
		:name => "Πολιτική Υγείας"
	},
	{
		first_page: 55,
		last_page: 85
	}],
	[{
		:id => 4,
		:name => "Πολιτική Απασχόλισης"
	},
	{
		first_page: 88,
		last_page: 108
	}],
	[{
		:id => 5,
		:name => "Εκπαιδευτική Πολιτική"
	},
	{
		first_page: 110,
		last_page: 126
	}],
	[{
		:id => 6,
		:name => "Αντεγκληματική Πολιτική"
	},
	{
		first_page: 153,
		last_page: 166
	}],
	[{
		:id => 7,
		:name => "Μεταναστευτική Πολιτική"
	},
	{
		first_page: 129,
		last_page: 142
	}],
	[{
		:id => 8,
		:name => "Πολιτική Φύλου"
	},
	{
		first_page: 169,
		last_page: 177
	}],
	[{
		:id => 9,
		:name => "Στεγαστική Πολιτική"
	},
	{
		first_page: 181,
		last_page: 197
	}],
	[{
		:id => 10,
		:name => "Πολιτική Περιβάλλοντος"
	},
	{
		first_page: 200,
		last_page: 223
	}],
	[{
		:id => 11,
		:name => "Κοινωνική Έρευνα"
	},
	{
		first_page: 226,
		last_page: 241
	}]
]

# number_of_pages = opts[:last_page] - opts[:first_page]

def scrap_data(opts, code, category_hash)
	# Keys for institution hash
	keys = ["name", "status", "year", "website", "description", "powers", "areas"]

	# Clear txts
	bootstrap_dir(TXT_PATH)

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
			puts line if line.strip == "/\d+/"
			# print "\r#{institution_counter}"
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
		filename = ""
		File.open("#{TXT_PATH}/#{txtfile}", "r") { |file|
			size = file.readlines.size
			filename = File.basename(file, ".*")
		}

		data = File.open("#{TXT_PATH}/#{txtfile}").read()
		count = data.count(':')
		next if count < 3

		# Skip pathological cases
		# next if (txtfile == "104.txt" ||
		# 		txtfile == "110.txt")

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

		# Load lines of txtfile in memory
		lines = File.readlines("#{TXT_PATH}/#{txtfile}")

		# If the last line is number remove it from array
		if /\d+/.match(lines[-1])
			lines.delete_at(-1)
		end

		counter = 0
		clean_line = Array.new
		name_array = Array.new
		hash = Hash.new

		# Create hash from txfile
		for line in lines do
			if (line.include? ':')
				value = clean_line.join(" ").gsub("\n", "")
				if (value.include? ':')
					value = value.slice(value.index(":")..-1).gsub(":", "").strip
				end
				hash[:"#{keys[counter]}"] = value
				clean_line.clear
				clean_line.push(line)
				counter += 1
				if (line == lines[-1])
					value = clean_line.join(" ").gsub("\n", "")
					if (value.include? ':')
						value = value.slice(value.index(":")..-1).gsub(":", "").strip
					end
					hash[:"#{keys[counter]}"] = value
				end
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
			hash[:areas] = hash[:areas].gsub(/\d+$/, "").strip
		end

		# Check whether every key in keys exists in hash
		for key in keys
			if !hash.key?(:"#{key}")
				hash[:"#{key}"] = ""
			end
		end

		# Add category key
		hash[:category] = category_hash

		# Write json file for institution
		File.open("data/json/#{code}-#{filename}.json", "w") { |json_file|
			json_file.write(hash.to_json)
		}
	end
	puts "\nDone"
end

for institution_category in categories_array
	puts "---------------" + institution_category[0][:name] + "---------------"
	scrap_data(institution_category[1], institution_category[0][:id], institution_category[0])
end