# frozen_string_literal: true

# Class that parses step definitions from Ruby files

# Step Parser
class StepParser
  attr_reader :steps

  def initialize
    @steps = []
  end

  def read(file)
    @current_file = file
    @line_number = 0
    @lines = IO.read(file).split(/\r?\n/)
    parse_lines
  end

  private

  def next_line
    @line_number += 1
    @lines.shift
  end

  def unread(line)
    @line_number -= 1
    @lines.unshift(line)
  end

  def parse_lines
    @comments = []
    until @lines.empty?
      line = next_line
      case line
      when /^ *#/
        @comments << line
      when /^(Given|When|Then|And|Before|After|AfterStep|Transform)( |\()/
        unread(line)
        parse_step
        @comments = []
      when /^\s+(Given|When|Then|And|Before|After|AfterStep|Transform)( |\()/
        puts "WARNING:  Indented step definition in file #{@current_file}:  #{line}"
        @comments = []
      else
        @comments = []
      end

    end
  end

  def parse_step
    name = parse_step_name(@lines.first).split("') do")[0].concat("')")
    line_number = @line_number + 1
    code = []
    headers = parse_headers(@comments)
    line = ''
    while !@lines.empty? && (line !~ /^end\s*$/)
      line = next_line
      code << line unless line.start_with?('#')
    end

    @steps << { type: 'Step',
                name: name,
                filename: @current_file,
                code: code,
                line_number: line_number,
                comments: @comments,
                headers: headers,
                anchor: "#{File.basename(@current_file, '.*')}_#{line_number}" }
  end

  def parse_headers(lines)
    headers = {}
    lines.each do |line|
      next unless line.match(/^ *# @(\w+).*/)

      tag = line.sub(/^ *# @(\w+).*/, '\1')
      value = line.sub(/^ *# *@(\w+) (.*)/, '\2').gsub('\ ', ' ')
      if headers[tag]
        headers[tag] = [headers[tag]] unless headers[tag].is_a?(Array)
        headers[tag] << value
      else
        headers[tag] = value unless tag.nil? || value.nil?
      end
    end
    headers
  end

  def parse_step_type(line)
    line.sub(/^([A-Za-z]+).*/, '\1')
  end

  def parse_step_name(line)
    line = line.sub(%r{^(Given|When|Then|And|Transform) *(\()? */\^?(.*?)\$?/.*}, '\3')
    line.gsub('\ ', ' ')
  end
end
