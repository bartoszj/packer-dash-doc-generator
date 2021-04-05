require "nokogiri"
require "erb"
require "sqlite3"
require "pathname"

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
    raise "Empty name for #{path}" if name.empty?
    @db.execute <<-SQL, name: name, type: type, path: path
      INSERT OR IGNORE INTO searchIndex (name, type, path)
      VALUES(:name, :type, :path)
    SQL
  end
end

task default: [:clean, :build, :setup, :copy, :create_index, :package]

task :clean do
  rm_rf "out"
  rm_rf "Packer.docset"
end

task :build do
  sh "make build"
end

task :setup do
  mkdir_p "Packer.docset/Contents/Resources/Documents"

  # Icon
  # at older docs there is no retina icon
  if File::exist? "out/img/favicons/favicon-16x16.png" and File::exist? "out/img/favicons/favicon-32x32.png"
    cp "out/img/favicons/favicon-16x16.png", "Packer.docset/icon.png"
    cp "out/img/favicons/favicon-32x32.png", "Packer.docset/icon@2x.png"
  else
    abort("Icon not found")
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
  Dir.chdir("out") { file_list = Dir.glob("**/*").sort }

  file_list.each do |path|
    source = "out/#{path}"
    target = "Packer.docset/Contents/Resources/Documents/#{path}"

    case
    when source.match(/\/_next\/data/)
      next
    when File.stat(source).directory?
      mkdir_p target
    when source.match(/\.gz$/)
      next
    when source.match(/\.html$/)
      doc = Nokogiri::HTML(File.open(source).read)

      doc.title = doc.title.sub(" | Packer by HashiCorp", "")
      doc.title = doc.title.sub(" - Extending", "")
      doc.title = doc.title.sub(" - Other", "")
      doc.title = doc.title.sub(" - Post-Processors", "")
      doc.title = doc.title.sub(" - Post-Processor", "")
      doc.title = doc.title.sub(" - Builders", "")
      doc.title = doc.title.sub(" - Commands", "")
      doc.title = doc.title.sub(" - Provisioners", "")
      doc.title = doc.title.sub(" - Templates", "")
      doc.title = doc.title.sub(" - Getting Started", "")

      doc.xpath("//a[contains(@class, 'anchor')]").each do |e|
        a = Nokogiri::XML::Node.new "a", doc
        a["class"] = "dashAnchor"
        a["name"] = "//apple_ref/cpp/%{type}/%{name}" %
          {type: "Section", name: ERB::Util.url_encode(e.parent.children.last.text.strip)}
        e.previous = a
      end

      doc.xpath("//link[starts-with(@href, '/')]").each do |e|
        e["href"] = Pathname.new(e["href"]).relative_path_from(Pathname.new("/#{path}").dirname).to_s
      end

      doc.xpath("//a[starts-with(@href, '/')]").each do |e|
        e["href"] = Pathname.new(e["href"]).relative_path_from(Pathname.new("/#{path}").dirname).to_s
      end

      doc.xpath('//script').each do |script|
        if script.text != ""
          script.remove
        end
      end
      doc.xpath("//header").each do |e|
        e.remove
      end
      doc.xpath("//div[contains(@class, 'g-alert-banner')]").each do |e|
        e.remove
      end
      doc.xpath("//div[contains(@class, 'g-mega-nav')]").each do |e|
        e.remove
      end
      doc.xpath("//nav").each do |e|
        e.remove
      end
      doc.xpath("//div[contains(@class, 'g-product-subnav')]").each do |e|
        e.remove
      end
      doc.xpath("//div[contains(@class, 'g-search')]").each do |e|
        e.remove
      end
      doc.xpath("id('sidebar')").each do |e|
        e.remove
      end
      doc.xpath("id('edit-this-page')").each do |e|
        e.remove
      end
      doc.xpath("//footer").each do |e|
        e.remove
      end

      doc.xpath("//div[contains(@class, 'g-container')]").each do |e|
        e["class"] = nil
        e["style"] = "margin-left: 30px; margin-right: 30px;"
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
    # guides/packer-on-cicd
    Dir.glob("guides/packer-on-cicd/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Guide", path
    end
    # intro/getting-started
    Dir.glob("intro/getting-started/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Guide", path
    end
    # docs/builders
    Dir.glob("docs/builders/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Builtin", path
    end
    # docs/commands
    Dir.glob("docs/commands/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Command", path
    end
    # docs/communicators
    Dir.glob("docs/communicators/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Delegate", path
    end
    # docs/core-configuration
    Dir.glob("docs/core-configuration/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Mixin", path
    end
    # docs/debugging
    Dir.glob("docs/debugging/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Mixin", path
    end
    # docs/environment-variables
    Dir.glob("docs/environment-variables/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Mixin", path
    end
    # docs/extending
    Dir.glob("docs/extending/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Extension", path
    end
    # docs/install
    Dir.glob("docs/install/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Instruction", path
    end
    # docs/post-processors
    Dir.glob("docs/post-processors/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Procedure", path
    end
    # docs/provisioners
    Dir.glob("docs/provisioners/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Provisioner", path
    end
    # docs/templates
    Dir.glob("docs/templates/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Macro", path
    end
    # docs/terminology
    Dir.glob("docs/terminology/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Word", path
    end
  end
end

task :import do
  sh "open Packer.docset"
end

task :package do
  sh "tar --exclude='.DS_Store' -cvzf Packer.tgz Packer.docset"
end
