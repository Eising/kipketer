Sequel.migration do
    change do
        set_column_type :templates, :fields, String, :text => true
    end
end
