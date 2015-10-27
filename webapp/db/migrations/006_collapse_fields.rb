require 'json'
Sequel.migration do
    up do
        # add defaults column to replace cpe_defaults and backbone_defaults
        add_column :forms, :defaults, String, :text => true
        self[:forms].select(:id, :cpe_defaults, :backbone_defaults, :defaults).all do |r|
            cpe = JSON.parse(r[:cpe_defaults])
            bb = JSON.parse(r[:backbone_defaults])
            defaults = bb.merge cpe
            self[:forms].where(:id => r[:id]).update(:defaults => defaults.to_json)
        end
        drop_column :forms, :cpe_defaults
        drop_column :forms, :backbone_defaults

        # Do the same for Tests.cpe_template_fields and
        # Tests.backbone_template_fields
        add_column :tests, :template_fields, String, :text => true
        self[:tests].select(:id, :cpe_template_fields, :backbone_template_fields).all do |r|
            cpe = JSON.parse(r[:cpe_template_fields])
            bb = JSON.parse(r[:backbone_template_fields])
            template = cpe.merge bb
            self[:tests].where(:id => r[:id]).update(:template_fields => template.to_json)
        end

        drop_column :tests, :cpe_template_fields
        drop_column :tests, :backbone_template_fields

    end
    down do
        # We copy defaults to both 
        add_column :forms, :cpe_defaults, String, :text => true
        add_column :forms, :backbone_defaults, String, :text => true

        self[:forms].select(:id, :defaults).all do |r|
            self[:forms].where(:id => r[:id]).update(:cpe_defaults => r[:defaults], :backbone_defaults => r[:defaults])
        end
        drop_column :forms, :defaults
        
        add_column :tests, :cpe_template_fields, String, :text => true
        add_column :tests, :backbone_template_fields, String, :text => true
        self[:tests].select(:id, :template_fields).all do |r|
            self[:forms].where(:id => r[:id]).update(:cpe_template_fields => r[:template_fields], :backbone_template_fields => r[:template_fields])
        end

        drop_column :tests, :template_fields

    end
end

        

