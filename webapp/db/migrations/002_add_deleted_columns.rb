Sequel.migration do
    change do
        add_column :templates, :deleted, TrueClass, :defaults => false
        add_column :forms, :deleted, TrueClass, :defaults => false
    end
end
