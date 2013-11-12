#!/usr/bin/env ruby
#-*- encoding: utf-8 -*-

require 'optparse'

require_relative 'step_parser'
require_relative 'confluence_step_outputter'
require_relative 'html_step_outputter'


# Parse command line
options = {}
opts = OptionParser.new do |opts|
  opts.banner = "Usage: cuke-steps.rb [options] <directories...>"

  opts.on("-o", "--output FILE", "Output to FILE") do |file|
    options[:file] = file
  end
  opts.on("-f", "--format FMT", "Select output format: cf, html") do |format|
    options[:format] = format
  end
end
opts.parse!(ARGV)

# Default output options
if options[:file] && !options[:format]
  options[:format] = options[:file].sub(/^.*\./, "")
end
if !options[:format]
  options[:format] = "html"
end
if options[:format] && !options[:file]
  options[:file] = "steps.#{options[:format]}"
end


# All other arguments are treated as input directories
dirs = ARGV
if dirs.size == 0
  puts "No source directories provided, use -h for help"
  exit 1
end

# Setup output
case options[:format]
when 'cf'
  output = ConfluenceStepOutputter.new(options[:file])
when 'html'
  output = HtmlStepOutputter.new(options[:file])
else
  puts "Unknown output format: #{options[:format]}"
  exit 1
end
puts "Writing output to file '#{options[:file]}'"


# Sort primarily by step type, secondarily by step definition
sorter = lambda do |a,b|
  a[:name].downcase <=> b[:name].downcase
end


# Read files and output
all_steps = []
file_list = []
output.header
dirs.each do |dir|
  dir = dir.sub(/\/+$/, "")
  Dir.glob("#{dir}/**/*.rb") do |file|
    file_list << file
    s = StepParser.new
    s.read(file)
    steps = s.steps
    all_steps += steps
    output.start_file(file)
    steps.sort!(&sorter)
    steps.each { |s| output.step(s) }
    output.end_file
  end
end

output.start_all(file_list)
all_steps.sort!(&sorter)
all_steps.each { |s| output.step_link(s) }
output.end_all

output.footer
output.close
