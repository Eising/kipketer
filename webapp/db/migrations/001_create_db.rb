Sequel.migration do
    up do
        create_table :templates do
            primary_key :id
            String :contents, :text => true
            String :name
            String :description
            String :fields #key,value pairs of fields and their validators
            String :type # Backbone, CPE
        end

        create_table :forms do
            primary_key :id
            String :name
            Integer :backbone_template_id
            Integer :cpe_template_id
            String :cpe_defaults #key,value pairs of default values
            String :backbone_defaults #key,value pairs of default values
        end

        create_table :tests do
            primary_key :id
            String :crid
            String :customer
            String :location
            Fixnum :speed
            String :form_id
            String :cpe_template_fields, :text => true
            String :backbone_template_fields, :text => true
            TrueClass :rfs, :defaults => false
            TrueClass :deleted, :defaults => false
            DateTime :timestamp
            Date :deadline
        end
    end
    down do
        drop_table :templates
        drop_table :forms
        drop_table :tests
    end
end
