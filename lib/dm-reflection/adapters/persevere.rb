module DataMapper
  module Reflection
    module PersevereAdapter
      
      ##
      # Convert the JSON Schema type into a DataMapper type
      # 
      # @todo This should be verified to identify all mysql primitive types 
      #       and that they map to the correct DataMapper/Ruby types.
      # 
      # @param [String] db_type type specified by the database
      # @param [String] optional format format specification for string attributes
      # @return [Type] a DataMapper or Ruby type object.
      # 
      def get_type(db_type, format = nil)
        db_type.gsub!(/\(\d*\)/, '')
        case db_type
        when 'serial'    then DataMapper::Types::Serial
        when 'integer'   then Integer
        when 'number'    then BigDecimal 
        when 'number'    then Float      
        when 'boolean'   then DataMapper::Types::Boolean
        when 'string'    then 
          case format
            when nil         then String
            when 'date-time' then DateTime
            when 'date'      then Date
            when 'time'      then Time
            when 'uri'       then DataMapper::Types::URI
          end
        end
      end
      ##
      # Get the list of schema names
      # 
      # @return [String Array] the names of the schemas in the server.
      # 
      def get_storage_names
        @schemas = self.get_schema
        @schemas.map { |schema| schema['id'] }
      end

      ##
      # Get the attribute specifications for a specific schema
      # 
      # @todo Consider returning actual DataMapper::Properties from this. 
      #       It would probably require passing in a Model Object.
      # 
      # @param [String] table the name of the schema to get attribute specifications for
      # @return [Hash] the column specs are returned in a hash keyed by `:name`, `:field`, `:type`, `:required`, `:default`, `:key`
      # 
      def get_properties(table)
        results = Array.new
        schema = self.get_schema(table)[0]
        schema['properties'].each_pair do |key, value|
          property = {:name => key, :type => get_type(value['type'], value['format']) }
          property.merge!({ :required => !value['optional'], 
                         :default => value['default'], 
                         :key => value.has_key?('index') && value['index'] }) unless property[:type] == DataMapper::Types::Serial
          results << property
        end
        return results
      end
      
    end # module PersevereAdapter
  end # module Reflection
end # module DataMapper