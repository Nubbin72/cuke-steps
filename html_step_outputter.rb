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
        left: 209px;
        font-family: Verdana,sans-serif;
        font-size: 15px;
        line-height: 1.5;
      }
      h1, h2, h3, h4, h5, h6 {
        font-family: "Segoe UI",Arial,sans-serif;
        font-weight: 400;
        margin: 10px 0;
      }
      h1{
        font-size: 42px;
      }
      h2{
        font-size: 32px;
      }
      h3{
        font-size: 24px;
      }
      ul{
        padding: 0;
        list-style-type: none;
      }
      .link{
        cursor: pointer;
        text-decoration: underline;
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
      .stepDesc{
        font-weight: normal;
      }
      .source {
        color: #FFFFFF;
        box-shadow: none;
        background-color: #ea0a8e !important;
        border-radius: 5px;
        font-size: 17px;
        font-family: 'Source Sans Pro', sans-serif;
        padding: 6px 18px;
        outline-width: 0;
        margin-bottom: 16px!important;
        border: none;
        display: inline-block;
        vertical-align: middle;
        overflow: hidden;
        text-decoration: none;
        text-align: center;
        cursor: pointer;
        white-space: nowrap;
        line-height: 1.5;
      }
      .example {
        font-family: monospace;
        background-color: #f0f0f0;
        padding: 5px;
        padding-left: 15px;
        font-weight: normal;
      }
      table {
        border-collapse: collapse;
        min-width: 20%;
        font-family: Verdana,sans-serif;
        font-size: 15px;
        line-height: 1.5;
      }
      td, th {
        border: 1px solid #dbdbdb;
        text-align: center;
        padding: 8px;
      }
      # tr:nth-child(even) {
      #   background-color: #dbdbdb;
      # }
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
        font-family: "Segoe UI",Arial,sans-serif;
        display: block;
        padding: 2px 1px 1px 16px;
        background-color: transparent;
        font-size: 15px;
        line-height: 1.5;
        text-decoration: none;
        color:inherit;
      }
      .leftnav {
        position:fixed;
        left:0;
        top:0;
        height: 100%;
        background-color: #E7E9EB;
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
    @file.puts %(</ul>)
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<div class='leftnav'>)
    @file.puts %(<h2>Navigation</h2>)

    files.each do |file|
      @file.puts %(<li><a class='linktag' href="##{File.basename(file, '.*')}">#{File.basename(file.split('_').join(' '), '.*')}</a>)
    end
  end

  def end_directory
    @file.puts %(</div>)
  end

  def title
    @file.puts %(<h1>Step Definition Files</h1>)
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
    @file.puts %(<li name="#{step[:anchor]}" class='stepdockey'>Step: <pre><code class="text">#{CGI.escapeHTML(step[:name])}</code></pre>)

    # Output step description
    unless step[:description].empty?
      @file.puts %(<li class='stepdockey'>Description:)
      @file.puts %(<pre><div class="stepDesc">#{step[:description]}</div></pre>)
    end

    # Output parameters in table
    unless step[:headers].empty?
      @file.puts %(<li class='stepdockey'>Parameters:)
      @file.puts %(<pre><table class='stepdoctable'><tr>)
      step[:headers].each do |key, _|
        @file.puts %(<th>#{key}</th>) unless key.downcase == 'example'
      end
      @file.puts %(</tr><tr>)
      step[:headers].each do |key, value|
        @file.puts %(<td>#{value}</td>) unless key.downcase == 'example'
      end
      @file.puts %(</tr></table></pre>)

      # Output examples at the bottom
      step[:headers].each do |key, value|
        if key.downcase == 'example'
          value = value.join('<br>') if value.is_a? Array
          @file.puts %(<li class='stepdockey'>#{key.capitalize}:<pre><div class="example"">#{value}</div></pre>)
        end
      end
    end

    @file.puts %(<li>)
    @file.puts %(  <a href="#" onclick="$('##{id}').slideToggle(); return false;" class="source">View Source</a>)
    @file.puts %(  <div id="#{id}" class="extrainfo">)
    @file.puts %(    <a class="link" href="#{@url}-/blob/master/#{step[:filename]}#L#{step[:line_number]}"><p>#{CGI.escapeHTML(step[:filename])}:#{step[:line_number]}</p></a>)
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
