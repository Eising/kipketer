Sequel.migration do
    change do
        add_column :forms, :inconsistent, TrueClass
    end
end

