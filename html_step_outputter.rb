# frozen_string_literal: true

# Outputter that generates HTML markup
# Feel free to customize the below code for your needs

require 'cgi'
require 'fileutils'

class HtmlStepOutputter
  def initialize(file)
    @file = File.open(file, 'w')
    @previous_type = ''
    @id_number = 0
  end

  # HTML file header - customize as needed
  def header
    @file.puts <<-HEADER
      <!DOCTYPE html>
      <html>
      <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <title>Cucumber step documentation</title>
      <style>
      body{
        position: absolute;
        left: 250px;
      }
      .stepdefs li {
        margin-bottom: 0.25em;
        list-style-type: none;
        font-weight: bold;
      }
      .stepdef {
        color: #111;
        text-decoration: none;
      }
      .source {
        color: #787878;
        text-decoration: none;
        text-decoration: underline;
        font-size: 80%;
      }
      .example {
        font-family: monospace;
        background-color: #f0f0f0;
        padding: 5px;
        padding-left: 15px;
        font-weight: normal;
      }
      table {
        font-family: arial, sans-serif;
        border-collapse: collapse;
        min-width: 20%;
      }
      td, th {
        border: 1px solid #dbdbdb;
        text-align: center;
        padding: 8px;
      }
      # tr:nth-child(even) {
      #   background-color: #dbdbdb;
      # }
      .stepDesc{
        font-weight: normal;
      }
      .stepdoctable{
        font-weight: normal;
      }
      .stepdocvalue {
        # margin-left: 25px;
        font-weight: normal;
        font-size: 110%;
      }
      .stepdockey {
        font-weight: bold;
      }
      .extrainfo {
        display: none;
        overflow: hidden; /* Fixes jumping issue in jQuery slideToggle() */
        font-weight: normal;
      }
      .linktag {
        text-decoration: none;
        color:inherit;
      }
      .leftnav {
        position:fixed;
        left:0;
        top:0;
        height: 100%;
        background-color: white;
        border: 1px solid black;
        padding: 5px;
        padding-left: 15px;
        padding-right: 15px;
        list-style: none;
      }
      </style>
      <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
      <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.2.0/styles/default.min.css">
      <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.2.0/highlight.min.js"></script>
      <script>hljs.highlightAll();</script>
      </head>
      <body>
    HEADER
  end

  def footer
    @file.puts <<-FOOTER
      </ul>
      <p>&nbsp;</p>
      <p><em>Documentation generated #{Time.now}</em></p>
      </body>
      </html>
    FOOTER
  end

  def close
    @file.close
  end

  def options(url)
    @url = url
  end

  def start_file(file, index)
    @file.puts %(</ul>) if @previous_type != ''
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<a name="#{File.basename(file, '.*')}"><h2>#{index + 1}. #{File.basename(file, '.*')}</h2></a>)
    @previous_type = ''
  end

  def end_file
    @file.puts '<hr noshade size=1>'
  end

  def start_directory(files)
    @file.puts %(</ul>)
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<div class='leftnav'>)
    @file.puts %(<h2>Step Definition Files</h2>)

    files.each_with_index do |file, index|
      @file.puts %(<li><a class='linktag' href="##{File.basename(file, '.*')}">#{index + 1}. #{File.basename(file.split('_').join(' '), '.*')}</a>)
    end
  end

  def end_directory
    @file.puts %(</div>)
  end

  def step(step)
    if @previous_type != step[:type]
      @file.puts %(</ul>) if @previous_type != ''
      @file.puts %(<ul class="stepdefs">)
      @previous_type = step[:type]
    end

    id = new_id
    @file.puts %(<div>)
    @file.puts %(<hr noshade size=1>)
    @file.puts %(<a name="#{step[:anchor]}"><li class='stepdockey'>Step: <pre><code class="text">#{CGI.escapeHTML(step[:name])}</code></pre></a>)

    # Output step description
    unless step[:description].empty?
      @file.puts %(<li class='stepdockey'>Description:)
      @file.puts %(<br><div class="stepDesc">#{step[:description]}</div>)
    end

    # Output parameters in table
    unless step[:headers].empty?
      @file.puts %(<li class='stepdockey'>Parameters:)
      @file.puts %(<table class='stepdoctable'><tr>)
      step[:headers].each do |key, _|
        @file.puts %(<th>#{key}</th>) unless key.downcase == 'example'
      end
      @file.puts %(</tr><tr>)
      step[:headers].each do |key, value|
        @file.puts %(<td>#{value}</td>) unless key.downcase == 'example'
      end
      @file.puts %(</tr></table>)

      # Output examples at the bottom
      step[:headers].each do |key, value|
        if key.downcase == 'example'
          value = value.join('<br>') if value.is_a? Array
          @file.puts %(<li class='stepdockey'>#{key.capitalize}:<br><div class="example"">#{value}</div>)
        end
      end
    end

    @file.puts %(<li>)
    @file.puts %(  <a href="#" onclick="$('##{id}').slideToggle(); return false;" class="source">View Source</a>)
    @file.puts %(  <div id="#{id}" class="extrainfo">)
    @file.puts %(    <a href="#{@url}-/blob/master/#{step[:filename]}#L#{step[:line_number]}"><p style="color: #888;">#{CGI.escapeHTML(step[:filename])}:#{step[:line_number]}</p></a>)
    @file.puts %(      <pre><code class="language-ruby">)
    step[:code].each do |line|
      @file.puts %(   #{CGI.escapeHTML(line)})
    end
    @file.puts %(      </code></pre>)
    @file.puts %(  </div>)
    @file.puts %(</li>)
    @file.puts %(</div>)
  end

  def step_link(step)
    @file.puts %(<a class='linktag' href="##{step[:anchor]}"><li>#{CGI.escapeHTML(step[:name])}</a>)
  end

  private

  def new_id
    @id_number += 1
    "id#{@id_number}"
  end
end
