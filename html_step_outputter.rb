# Outputter that generates HTML markup
# Feel free to customize the below code for your needs

require 'cgi'
require 'fileutils'

class HtmlStepOutputter
  
  def initialize(file)
    @file = File.open(file, 'w')
    @previous_type = ""
    @id_number = 0
  end
  
  # HTML file header - customize as needed
  def header
    @file.puts <<-eos
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
      .stepdocvalue {
        margin-left: 25px;
        font-weight: normal;
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
      .rightnav {
        position:absolute;
        right:0;
        top:0;
        background-color: white;
        border: 1px solid black;
        padding: 5px;
        font-size: smaller;
      }
      </style>
      <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
      </head>
      <body>
    eos
  end
  
  def footer
    @file.puts <<-eos
      </ul>
      <p>&nbsp;</p>
      <p><em>Documentation generated #{Time.now}</em></p>
      </body>
      </html>
    eos
  end

  
  def close
    @file.close
  end

  def start_file(file)
    @file.puts %(</ul>) if @previous_type != ""
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<a name="#{File.basename(file, '.*')}"><h2>#{File.basename(file, '.*')}</h2></a>)
    @previous_type = ""
  end

  def end_file
    @file.puts "<hr noshade size=1>"
  end

  def start_all(files)
    @file.puts %(</ul>)
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<div class='rightnav'>)
    @file.puts %(<h2>Definition Files</h2>)

    files.each do |file|
      @file.puts %(<li><a class='linktag' href="##{File.basename(file, '.*')}">#{File.basename(file, '.*')}</a>)
    end

    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<h2>All definitions alphabetically</h2>)
    @previous_type = ""
  end

  def end_all
    @file.puts %(</div>)
  end

  def step(step)
    if @previous_type != step[:type]
      @file.puts %(</ul>) if @previous_type != ""
      @file.puts %(<ul class="stepdefs">)
      @previous_type = step[:type]
    end

    id = new_id
    @file.puts %(<hr noshade size=1>)
    @file.puts %(<a name="#{step[:anchor]}"><li class='stepdockey'>Step: <div class='stepdocvalue'> #{CGI.escapeHTML(step[:name])} </div></a>)

    step[:headers].each do |key, value|
      value = value.join('<br>') if value.is_a? Array
      @file.puts %(<li class='stepdockey'>#{key.capitalize}:<br><div class='stepdocvalue'> #{value} </div>)
    end
    @file.puts %(<li>)
    @file.puts %(  <a href="#" onclick="$('##{id}').slideToggle(); return false;" class="stepdef">View Source</a>)
    @file.puts %(  <div id="#{id}" class="extrainfo">)
    @file.puts %(    <p style="color: #888;">#{CGI.escapeHTML(step[:filename])}:#{step[:line_number]}</p>)
    @file.puts %(      <pre style="background-color: #ddd; padding-top: 1.2em;">)
    step[:code].each do |line|
      @file.puts %(   #{CGI.escapeHTML(line)})
    end
    @file.puts %(      </pre>)
    @file.puts %(  </div>)
    @file.puts %(</li>)
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
