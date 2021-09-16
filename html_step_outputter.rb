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
    @file.puts <<-END_OF_HEADER
      <!DOCTYPE html>
      <html>
      <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <title>Cucumber step documentation</title>
      <style>
      .stepdefs {
        font-size: smaller;
      }
      .stepdefs li {
        margin-bottom: 0.25em;
        list-style-type: none;
        font-weight: bold;
      }
      .stepdefs li:before {
        content: "\u00BB";
        font-size: larger;
        padding-right: 0.3em;
        font-weight: bold;
      }
      .stepdef {
        color: #111;
        text-decoration: none;
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
        border: 1px solid #f0f0f0;
        text-align: center;
        padding: 8px;
      }
      tr:nth-child(even) {
        background-color: #f0f0f0;
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
      </style>
      <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
      <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.2.0/styles/default.min.css">
      <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.2.0/highlight.min.js"></script>
      <script>hljs.highlightAll();</script>
      </head>
      <body>
    END_OF_HEADER
  end

  def footer
    @file.puts <<-END_OF_FOOTER
      </ul>
      <p>&nbsp;</p>
      <p><em>Documentation generated #{Time.now}</em></p>
      </body>
      </html>
    END_OF_FOOTER
  end

  def close
    @file.close
  end

  def start_file(file)
    @file.puts %(</ul>) if @previous_type != ''
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<a name="#{File.basename(file, '.*')}"><h2>#{File.basename(file, '.*')}</h2></a>)
    @previous_type = ''
  end

  def end_file
    @file.puts '<hr noshade size=1>'
  end

  def start_directory(files)
    @file.puts %(<h2>Step Definition Files</h2>)

    files.each do |file|
      @file.puts %(<li><a class='linktag' href="##{File.basename(file, '.*')}">#{File.basename(file.split('_').join(' '), '.*')}</a>)
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
    # @file.puts %(<a name="#{step[:anchor]}"><li class='stepdockey'>Step: <div class='stepdocvalue'> #{CGI.escapeHTML(step[:name])} </div></a>)
    @file.puts %(<a name="#{step[:anchor]}"><li class='stepdockey'>Step: <pre><code class="text">#{CGI.escapeHTML(step[:name])}</code></pre></a>)

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
    @file.puts %(  <a href="#" onclick="$('##{id}').slideToggle(); return false;" class="stepdef">View Source</a>)
    @file.puts %(  <div id="#{id}" class="extrainfo">)
    @file.puts %(    <p style="color: #888;">#{CGI.escapeHTML(step[:filename])}:#{step[:line_number]}</p>)
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
