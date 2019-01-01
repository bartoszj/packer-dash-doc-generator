require "nokogiri"
require "erb"
require "sqlite3"

class Index
  attr_accessor :db

  def initialize(path)
    @db = SQLite3::Database.new path
  end

  def drop
    @db.execute <<-SQL
      DROP TABLE IF EXISTS searchIndex
    SQL
  end

  def create
    db.execute <<-SQL
      CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT)
    SQL
    db.execute <<-SQL
      CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path)
    SQL
  end

  def reset
    drop
    create
  end

  def insert(type, path)
    doc = Nokogiri::HTML(File.open(path).read)
    name = doc.title.sub(" - Packer by HashiCorp", "").sub(/.*: (.*)/, "\\1")
    @db.execute <<-SQL, name: name, type: type, path: path
      INSERT OR IGNORE INTO searchIndex (name, type, path)
      VALUES(:name, :type, :path)
    SQL
  end
end

task default: [:clean, :build, :setup, :copy, :create_index, :package]

task :clean do
  rm_rf "build"
  rm_rf "Packer.docset"
end

task :build do
  config_extensions = ["activate :relative_assets", "set :relative_links, true", "set :strip_index_file, false"]
  File.open("config.rb", "a") do |f|
    config_extensions.each do |ce|
      if File.readlines("config.rb").grep(Regexp.new ce).size == 0
        f.puts ce
      end
    end
  end

  sh "bundle"
  sh "bundle exec middleman build"
end

task :setup do
  mkdir_p "Packer.docset/Contents/Resources/Documents"

  # Icon
  # at older docs there is no retina icon
  if File::exist? "source/assets/images/favicons/favicon-16x16.png" and File::exist? "source/assets/images/favicons/favicon-32x32.png"
    cp "source/assets/images/favicons/favicon-16x16.png", "Packer.docset/icon.png"
    cp "source/assets/images/favicons/favicon-32x32.png", "Packer.docset/icon@2x.png"
  elsif File::exists? "source/assets/images/favicon.png"
    cp "source/assets/images/favicon.png", "Packer.docset/icon.png"
  else
    cp "source/images/favicon.png", "Packer.docset/icon.png"
  end

  # Info.plist
  File.open("Packer.docset/Contents/Info.plist", "w") do |f|
    f.write <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
    <key>CFBundleIdentifier</key>
    <string>packer</string>
    <key>CFBundleName</key>
    <string>Packer</string>
    <key>DocSetPlatformFamily</key>
    <string>packer</string>
    <key>isDashDocset</key>
    <true/>
    <key>DashDocSetFamily</key>
    <string>dashtoc</string>
    <key>dashIndexFilePath</key>
    <string>docs/index.html</string>
    <key>DashDocSetFallbackURL</key>
    <string>https://www.packer.io/</string>
    </dict>
</plist>
    XML
  end
end

task :copy do
  file_list = []
  Dir.chdir("build") { file_list = Dir.glob("**/*").sort }

  file_list.each do |path|
    source = "build/#{path}"
    target = "Packer.docset/Contents/Resources/Documents/#{path}"

    case
    when File.stat(source).directory?
      mkdir_p target
    when source.match(/\.gz$/)
      next
    when source.match(/\.html$/)
      doc = Nokogiri::HTML(File.open(source).read)

      doc.title = doc.title.sub(" - Packer by HashiCorp", "")

      doc.xpath("//a[contains(@class, 'anchor')]").each do |e|
        a = Nokogiri::XML::Node.new "a", doc
        a["class"] = "dashAnchor"
        a["name"] = "//apple_ref/cpp/%{type}/%{name}" %
          {type: "Section", name: ERB::Util.url_encode(e.parent.children.last.text.strip)}
        e.previous = a
      end

      doc.xpath('//script').each do |script|
        if script.text != ""
          script.remove
        end
      end
      doc.xpath("id('header')").each do |e|
        e.remove
      end
      doc.xpath("//div[contains(@class, 'mega-nav-sandbox')]").each do |e|
        e.remove
      end
      doc.xpath("//div[contains(@class, 'docs-sidebar')]").each do |e|
        e.parent.remove
      end
      doc.xpath("id('docs-sidebar')").each do |e|
        e.remove
      end
      doc.xpath("id('footer')").each do |e|
        e.remove
      end

      doc.xpath('//div[@id="inner"]/h1').each do |e|
        e["style"] = "margin-top: 0px"
      end
      doc.xpath("//div[contains(@role, 'main')]").each do |e|
        e["style"] = "width: 100%"
      end

      File.open(target, "w") { |f| f.write doc }
    else
      cp source, target
    end
  end
end

task :create_index do
  index = Index.new("Packer.docset/Contents/Resources/docSet.dsidx")
  index.reset

  Dir.chdir("Packer.docset/Contents/Resources/Documents") do
    # packer-on-cicd
    Dir.glob("guides/packer-on-cicd/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Guide", path
    end
    # getting-started
    Dir.glob("intro/getting-started/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Guide", path
    end
    # basics
    Dir.glob("docs/basics/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Word", path
    end
    # builders
    Dir.glob("docs/builders/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Builtin", path
    end
    # commands
    Dir.glob("docs/commands/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Command", path
    end
    # extending
    Dir.glob("docs/extending/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Extension", path
    end
    # install
    Dir.glob("docs/install/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Instruction", path
    end
    # other
    Dir.glob("docs/other/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Mixin", path
    end
    # post-processors
    Dir.glob("docs/post-processors/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Procedure", path
    end
    # provisioners
    Dir.glob("docs/provisioners/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Provisioner", path
    end
    # templates
    Dir.glob("docs/templates/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Macro", path
    end
  end
end

task :import do
  sh "open Packer.docset"
end

task :package do
  sh "tar --exclude='.DS_Store' -cvzf Packer.tgz Packer.docset"
end
