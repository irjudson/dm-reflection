require File.dirname(__FILE__) + '/spec_helper'
require 'dm-reflection/builders/source_builder'

BLOGPOST = <<-RUBY
class BlogPost

  include DataMapper::Resource

  property :id, Serial

  property :created_at, DateTime
  property :body, Text, :length => 65535, :lazy => true
  property :updated_at, DateTime


end
RUBY

COMMENT = <<-RUBY
class Comment

  include DataMapper::Resource

  property :id, Serial

  property :created_at, DateTime
  property :body, Text, :length => 65535, :lazy => true
  property :updated_at, DateTime
  property :score, Integer


end
RUBY

REFLECTION_SOURCES = [ BLOGPOST, COMMENT ]

describe 'The DataMapper reflection module' do

  before(:each) do
    @adapter = repository(:default).adapter

    REFLECTION_SOURCES.each { |source| eval(source) }

    @models = {
      :BlogPost      => BLOGPOST,
      :Comment     => COMMENT,
    }
    
    @models.each_key { |model| Extlib::Inflection.constantize(model.to_s).auto_migrate! }
    @models.each_key { |model| remove_model_from_memory( Extlib::Inflection.constantize(model.to_s) ) }
  end

  after(:each) do
    @models.each_key do |model_name|
      next unless Object.const_defined?(model_name)
      model = Extlib::Inflection.constantize(model_name.to_s)
      model.auto_migrate_down!
      remove_model_from_memory(model)
    end
  end

  describe 'repository(:name).reflect' do
    it 'should reflect all the models in a repository' do      
      # Reflect the models back into memory.
      DataMapper::Reflection.reflect(:default)
      
      # Iterate through each model in memory and verify the source is the same as the original.
      # using model.to_ruby
      @models.each_pair do |model_name, source|
        model = Extlib::Inflection.constantize(model_name.to_s)
        reflected_source = model.to_ruby
        model.to_ruby.should == source
      end
    end
  end

  describe 'reflected model instance' do
    it 'should respond to default_repository_name and return the correct repo for a reflected model' do
      # Reflect the models back into memory.
      DataMapper::Reflection.reflect(:default)
      
      @models.each_key do |model_name|
        model = Extlib::Inflection.constantize(model_name.to_s)
        model.should respond_to(:default_repository_name)
        model.default_repository_name.should == :default
      end
    end
  end

  describe 'reflective adapter' do
    it 'should respond to get_storage_names and return an array of models' do
      @adapter.should respond_to(:get_storage_names)
      @adapter.get_storage_names.should be_kind_of(Array)
    end
    
    it "should respond to get_properties and return an array of properties" do
      @adapter.should respond_to(:get_properties)
      tables = @adapter.get_storage_names
      properties = @adapter.get_properties(tables[0])
      properties.should be_kind_of(Array)
      a_property = properties[0]
      a_property.should be_kind_of(Hash)
      a_property.keys.should include(:name)
      a_property.keys.should include(:type)
    end
  end

end
