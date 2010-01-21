# require 'csv'
module DataMapper
  module Reflection
    class CSV

      def self.describe_model(csv='tmp/data/test.csv')
        desc = {}
        desc.update( {'id' => "Ref" + csv.gsub(/.*\//,'').gsub('.csv', '')} )
        desc.update( {'properties' => {}} )
        csv = clean_csv(csv)
        attributes = csv[0].split(',')
        data_types = csv[1].split(',')
        unit_types = csv[2].split(',')
        attributes.each_with_index do |property, index|
          prop = property.gsub(' ', '_')
          prop = prop.downcase
          desc['properties'].update( {prop => {'type' => data_types[index]}} ) unless prop == "id"
        end
        desc
      end

      def self.clean_csv(csv=nil)
        clean_lines = []
        File.new(csv, 'r').each_line do |line|
          if line.chomp != ""
            clean_lines << line.chomp
          end
        end
        clean_lines
      end

      def self.import_data(csv, repo_name)
        model_name = "Ref" + csv.gsub(/.*\//,'').gsub('.csv','')
        puts repo_name
        # if repository(:"#{repo_name}").adapter.options[:adapter] == "persevere"
        json_schema = Object::const_get(model_name).to_json_schema_compatible_hash(:yogo)
        json_schema["id"] = "yogo/project/#{json_schema["id"]}"
        class_def = DataMapper::Factory.describe_model_from_json_schema(json_schema, :yogo)

        eval(class_def)
        yogo_model = eval("Yogo::Project::#{Object::const_get(model_name).name}")

        yogo_model.auto_upgrade!

        csv = clean_csv(csv)
        attributes = csv[0].split(',').map{|attribute| attribute.gsub(" ", "_").downcase}
        count =0
        csv[3..-1].each do |line|
          count +=1
          parameters = {:id => count.to_s}

          line.split(',').each_with_index do |attribute, index|
            parameters = parameters.update( {attributes[index].to_sym => attribute} )

          end unless line.nil?
          yogo_model.create!(parameters)
        end 
      end
      
      def self.import_data_to_model(csv, model, repo_name)
        csv = clean_csv(csv)
        attributes = csv[0].split(',').map{|attribute| attribute.gsub(" ", "_").downcase}
        count = 0
        csv[3..-1].each do |line|
          count +=1
          parameters = {:id => count.to_s}

          line.split(',').each_with_index do |attribute, index|
            parameters = parameters.update( {attributes[index].to_sym => attribute} )

          end unless line.nil?

          model.create!(parameters)
        end 
      end
    end
  end
end

