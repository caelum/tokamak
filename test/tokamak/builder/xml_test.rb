require 'test_helper'

class Tokamak::Builder::XmlTest < Test::Unit::TestCase

  def test_media_type_should_be_xml
    assert_equal ["application/xml","text/xml"], Tokamak::Builder::Xml.media_types
  end

  def test_the_most_simple_xml
    obj = [{ :foo => "bar" }]
    xml = Tokamak::Builder::Xml.build(obj) do |collection|
      collection.values do |values|
        values.id "an_id"
      end

      collection.members do |member, some_foos|
        member.values do |values|
          values.id some_foos[:foo]
        end
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "root" , xml.root.name
    assert_equal "an_id", xml.css("root id").first.text
    assert_equal "bar"  , xml.css("root > member > id").first.text
  end

  def test_root_set_on_builder
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj, :root => "foos") do |collection|
      collection.values do |values|
        values.id "an_id"
      end

      collection.members do |member, some_foos|
        member.values do |values|
          values.id some_foos[:foo]
        end
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "foos" , xml.root.name
    assert_equal "an_id", xml.css("foos id").first.text
    assert_equal "bar"  , xml.css("foos > member > id").first.text
  end

  def test_collection_set_on_members
    obj = { :foo => "bar" }
    a_collection = [1,2,3,4]
    xml = Tokamak::Builder::Xml.build(obj) do |collection|
      collection.values do |values|
        values.id "an_id"
      end

      collection.members(:collection => a_collection) do |member, number|
        member.values do |values|
          values.id number
        end
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "an_id", xml.css("root id").first.text
    assert_equal "1"    , xml.css("root > member > id").first.text
    assert_equal 4      , xml.css("root > member > id").size
  end

  def test_raise_exception_for_not_passing_a_collection_as_parameter_to_members
    obj = 42

    assert_raise Tokamak::BuilderError do
      json = Tokamak::Builder::Xml.build(obj) do |collection, number|
        collection.values do |values|
          values.id number
        end

        collection.members do |member, item|
          member.values do |values|
            values.id item
          end
        end
      end
    end
  end

  def test_root_set_on_members
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj) do |collection|
      collection.values do |values|
        values.id "an_id"
      end

      collection.members(:root => "foos") do |member, some_foos|
        member.values do |values|
          values.id some_foos[:foo]
        end
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "an_id", xml.css("root id").first.text
    assert_equal "bar"  , xml.css("root > foos > id").first.text
    assert_equal 2      , xml.css("root > foos > id").size
  end
  
  def test_values_that_should_be_an_array
    obj = [{ :foo => ["bar", "zoom"] }]
    xml = Tokamak::Builder::Xml.build(obj) do |collection|
      collection.values do |values|
        values.id "an_id"
      end

      collection.members do |member, some_foos|
        member.values do |values|
          values.ids []
          some_foos[:foo].each do |id|
            values.ids id
          end
        end
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "root" , xml.root.name
    assert_equal "an_id", xml.css("root id").first.text
    assert_equal ["bar", "zoom"], xml.css("root > member > ids").map { |id| id.text }
  end

  def test_nested_crazy_values
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj) do |collection|
      collection.values do |values|
        values.body {
          values.face {
            values.eyes  "blue"
            values.mouth "large"
          }
        }
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "blue" , xml.css("root > body > face > eyes").first.text
    assert_equal "large", xml.css("root > body > face > mouth").first.text
  end

  def test_xml_attributes_on_values
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj) do |collection|
      collection.values do |values|
        values.body(:type => "fat", :gender => "male") {
          values.face {
            values.eyes  "blue"
            values.mouth "large", :teeth_count => 32
          }
        }
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "fat" , xml.css("root > body").first["type"]
    assert_equal "32"  , xml.css("root > body > face > mouth").first["teeth_count"]
  end

  def test_xml_namespaces_on_values
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj) do |collection|
      collection.values do |values|
        values.body("xmlns:biology" => "http://a.biology.namespace.com") {
          values["biology"].face {
            values["biology"].eyes  "blue"
            values["biology"].mouth "large", :teeth_count => 32
          }
        }
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "biology", xml.at_xpath(".//biology:face", {"biology" => "http://a.biology.namespace.com"}).namespace.prefix
  end

  def test_build_full_collection
    time = Time.now
    some_articles = [
      {:id => 1, :title => "a great article", :updated => time},
      {:id => 2, :title => "another great article", :updated => time}
    ]

    xml = Tokamak::Builder::Xml.build(some_articles) do |collection|
      collection.values do |values|
        values.id      "http://example.com/json"
        values.title   "Feed"
        values.updated time

        values.author {
          values.name  "John Doe"
          values.email "joedoe@example.com"
        }

        values.author {
          values.name  "Foo Bar"
          values.email "foobar@example.com"
        }
      end

      collection.link("next"    , "http://a.link.com/next")
      collection.link("previous", "http://a.link.com/previous")

      collection.members(:root => "articles") do |member, article|
        member.values do |values|
          values.id      "uri:#{article[:id]}"
          values.title   article[:title]
          values.updated article[:updated]
        end

        member.link("image", "http://example.com/image/1")
        member.link("image", "http://example.com/image/2", :type => "application/json")
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "John Doe"               , xml.css("root > author").first.css("name").first.text
    assert_equal "foobar@example.com"     , xml.css("root > author").last.css("email").first.text

    assert_equal "http://a.link.com/next" , xml.css("root > link").first["href"]
    assert_equal "next"                   , xml.css("root > link").first["rel"]
    assert_equal "application/xml"        , xml.css("root > link").last["type"]

    assert_equal "uri:1"                      , xml.css("root > articles").first.css("id").first.text
    assert_equal "a great article"            , xml.css("root > articles").first.css("title").first.text
    assert_equal "http://example.com/image/1" , xml.css("root > articles").first.css("link").first["href"]
    assert_equal "image"                      , xml.css("root > articles").first.css("link").first["rel"]
    assert_equal "application/json"           , xml.css("root > articles").first.css("link").last["type"]
  end

  def test_build_full_member
    time = Time.now
    an_article = {:id => 1, :title => "a great article", :updated => time}

    xml = Tokamak::Builder::Xml.build(an_article, :root => "article") do |member, article|
      member.values do |values|
        values.id      "uri:#{article[:id]}"
        values.title   article[:title]
        values.updated article[:updated]

        values.domain("xmlns" => "http://a.namespace.com") {
          member.link("image", "http://example.com/image/1")
          member.link("image", "http://example.com/image/2", :type => "application/atom+xml")
        }
      end

      member.link("image", "http://example.com/image/1")
      member.link("image", "http://example.com/image/2", :type => "application/json")
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "http://example.com/image/1" , xml.css("article > link").first["href"]
    assert_equal "image"                      , xml.css("article > link").first["rel"]
    assert_equal "application/json"           , xml.css("article > link").last["type"]

    assert_equal "http://example.com/image/1" , xml.xpath("/article/xmlns:domain/xmlns:link", {"xmlns" => "http://a.namespace.com"}).first["href"]
    assert_equal "image"                      , xml.xpath("/article/xmlns:domain/xmlns:link", {"xmlns" => "http://a.namespace.com"}).first["rel"]
    assert_equal "application/atom+xml"       , xml.xpath("/article/xmlns:domain/xmlns:link", {"xmlns" => "http://a.namespace.com"}).last["type"]
  end
end

class Tokamak::Builder::XmlLambdaTest < Test::Unit::TestCase
  
  def xml_build_and_parse(&block)
    block ||= lambda {}
    xml = Tokamak::Builder::Xml.build_dsl({}, &block)
    Nokogiri::XML::Document.parse(xml)
  end

  def test_accepts_custom_values
    xml = xml_build_and_parse do
      name "erich"
    end

    assert_equal "erich", xml.css("root name").first.text
  end

  def test_supports_any_attribute_by_using_the_write_method
    xml = xml_build_and_parse do
      write :to_s , "22"
    end
    
    assert_equal "22", xml.css("root to_s").first.text
  end

  def test_id_method_is_also_accepted
    xml = xml_build_and_parse do
      id  "22"
    end

    assert_equal "22", xml.css("root id").first.text
  end

  def test_root_member_should_be_called_root
    xml = xml_build_and_parse

    assert_equal "root" , xml.root.name
  end

  def test_members
    obj = [{ :foo => "bar" }]
    xml = Tokamak::Builder::Xml.build(obj) do

      members do |member, some_foos|
        write :id, some_foos[:foo]
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "bar"  , xml.css("root > member > id").first.text
  end

  def test_root_set_on_builder
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj, :root => "foos") do
      write :id, "an_id"

      members do |member, some_foos|
        write :id, some_foos[:foo]
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "foos" , xml.root.name
    assert_equal "an_id", xml.css("foos id").first.text
    assert_equal "bar"  , xml.css("foos > member > id").first.text
  end
  
  def test_uses_outside_scope_when_passing_an_arg_to_the_builder
    helper = Object.new
    def helper.name
      "guilherme"
    end
    xml = Tokamak::Builder::Xml.build_dsl(helper) do |s|
      name s.name
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "guilherme", xml.css("root name").first.text
  end

  def test_uses_externally_declared_objects_if_accessible
    obj = { :category => "esporte" }
    xml = Tokamak::Builder::Xml.build_dsl({}) do |s|
      categoria obj[:category]
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "esporte", xml.css("root categoria").first.text
  end

  def test_collection_set_on_members
    obj = { :foo => "bar" }
    a_collection = [1,2,3,4]
    xml = Tokamak::Builder::Xml.build_dsl(obj) do
      write :id, "an_id"

      members(:collection => a_collection) do |member, item|
        write :id, item
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "an_id", xml.css("root id").first.text
    assert_equal "1"    , xml.css("root > member > id").first.text
    assert_equal 4      , xml.css("root > member > id").size
  end

  def test_raise_exception_for_not_passing_a_collection_as_parameter_to_members
    obj = 42

    assert_raise Tokamak::BuilderError do
      json = Tokamak::Builder::Json.build(obj) do
        write :id, number

        members do |member, item|
          write :id, item
        end
      end
    end
  end

  def test_root_set_on_members
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj) do

      members(:root => "foos") do |member, some_foos|
        write :id, some_foos[:foo]
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "bar"  , xml.css("root > foos > id").first.text
    assert_equal 2      , xml.css("root > foos > id").size
  end

  def test_nested_crazy_values
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj) do
      body {
        face {
          eyes  "blue"
          mouth "large"
        }
      }
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "blue" , xml.css("root > body > face > eyes").first.text
    assert_equal "large", xml.css("root > body > face > mouth").first.text
  end

  def test_xml_attributes_on_values
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj) do
        body(:type => "fat", :gender => "male") {
          face {
            eyes  "blue"
            mouth "large", :teeth_count => 32
          }
        }
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "fat" , xml.css("root > body").first["type"]
    assert_equal "32"  , xml.css("root > body > face > mouth").first["teeth_count"]
  end

  def test_xml_namespaces_on_values
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    xml = Tokamak::Builder::Xml.build(obj) do |collection|
      collection.values do |values|
        values.body("xmlns:biology" => "http://a.biology.namespace.com") {
          values["biology"].face {
            values["biology"].eyes  "blue"
            values["biology"].mouth "large", :teeth_count => 32
          }
        }
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "biology", xml.at_xpath(".//biology:face", {"biology" => "http://a.biology.namespace.com"}).namespace.prefix
  end

  def test_build_full_collection
    time = Time.now
    some_articles = [
      {:id => 1, :title => "a great article", :updated => time},
      {:id => 2, :title => "another great article", :updated => time}
    ]

    xml = Tokamak::Builder::Xml.build(some_articles) do
        write :id,      "http://example.com/json"
        title   "Feed"
        updated time

        author {
          name  "John Doe"
          email "joedoe@example.com"
        }

        author {
          name  "Foo Bar"
          email "foobar@example.com"
        }

      link("next"    , "http://a.link.com/next")
      link("previous", "http://a.link.com/previous")

      members(:root => "articles") do |member, article|
          write :id,      "uri:#{article[:id]}"
          title   article[:title]
          updated article[:updated]

        link("image", "http://example.com/image/1")
        link("image", "http://example.com/image/2", :type => "application/json")
      end
    end

    xml = Nokogiri::XML::Document.parse(xml)

    assert_equal "John Doe"               , xml.css("root > author").first.css("name").first.text
    assert_equal "foobar@example.com"     , xml.css("root > author").last.css("email").first.text

    assert_equal "http://a.link.com/next" , xml.css("root > link").first["href"]
    assert_equal "next"                   , xml.css("root > link").first["rel"]
    assert_equal "application/xml"        , xml.css("root > link").last["type"]

    assert_equal "uri:1"                      , xml.css("root > articles").first.css("id").first.text
    assert_equal "a great article"            , xml.css("root > articles").first.css("title").first.text
    assert_equal "http://example.com/image/1" , xml.css("root > articles").first.css("link").first["href"]
    assert_equal "image"                      , xml.css("root > articles").first.css("link").first["rel"]
    assert_equal "application/json"           , xml.css("root > articles").first.css("link").last["type"]
  end
end

