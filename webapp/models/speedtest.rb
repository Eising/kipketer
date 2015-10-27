Sequel::Model.plugin :xml_serializer
Sequel::Model.plugin :json_serializer
class Templates < Sequel::Model
    one_to_many :form_backbone_template, :class => :Forms, :key => :backbone_template_id
    one_to_many :form_cpe_template, :class => :Forms, :key => :cpe_template_id
end


class Forms < Sequel::Model
    many_to_one :backbone_template, :class => :Templates
    many_to_one :cpe_template, :class => :Templates
    one_to_many :test_form, :class => :Tests, :key => :form_id
end

class Tests < Sequel::Model
    many_to_one :form, :class => :Forms
    one_to_many :test_results, :class => :Results, :key => :test_id
    def template_fieldset
        return JSON.parse(self.template_fields)
    end

end

class Results < Sequel::Model
    many_to_one :test, :class => :Tests
end

class Processes < Sequel::Model
end

class Requests < Sequel::Model

end
