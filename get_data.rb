require 'rubygems'
require 'nokogiri'
require 'kristin'

PDF_PATH = 'raw/kp_foreis.pdf'
HTML_PATH = 'data/kp_foreis.html'

# pdf2htmlex/Kristin options
opts = {
	first_page: 11,
	last_page: 241
}

# Generate the html file with pdf2htmlex
Kristin.convert(PDF_PATH, HTML_PATH, opts)

