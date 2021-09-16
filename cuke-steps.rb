#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

require_relative 'step_parser'
require_relative 'html_step_outputter'

# Parse command line
options = {}
opts = OptionParser.new do |opts_|
  opts_.banner = 'Usage: cuke-steps.rb [options] <directories...>'

  opts_.on('-o', '--output FILE', 'Output to FILE') do |file|
    options[:file] = file
  end
  opts_.on('-f', '--format FMT', 'Select output format: html') do |format|
    options[:format] = format
  end
end
opts.parse!(ARGV)

# Default output options
options[:format] = options[:file].sub(/^.*\./, '') if options[:file] && !options[:format]
options[:format] = 'html' unless options[:format]
options[:file] = "steps.#{options[:format]}" if options[:format] && !options[:file]

# All other arguments are treated as input directories
dirs = ARGV
if dirs.size.zero?
  puts 'No source directories provided, use -h for help'
  exit 1
end

# Setup output
case options[:format]
when 'html'
  output = HtmlStepOutputter.new(options[:file])
else
  puts "Unknown output format: #{options[:format]}"
  exit 1
end
puts "Writing output to file '#{options[:file]}'"

# Sort step type name
sorter = lambda do |a, b|
  a[:name].downcase <=> b[:name].downcase
end

# Read files
file_list = []
dirs.each do |dir|
  dir = dir.sub(%r{/+$}, '')
  Dir.glob("#{dir}/**/*.rb") do |file|
    file_list << file
  end
end

# Output
output.header
output.start_directory(file_list)
output.end_directory

file_list.each do |file|
  sp = StepParser.new
  sp.read(file)
  steps = sp.steps
  output.start_file(file)
  steps.sort!(&sorter)
  steps.each { |s| output.step(s) }
  output.end_file
end

output.footer
output.close
