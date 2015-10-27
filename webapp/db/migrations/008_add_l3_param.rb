Sequel.migration do
    change do
        add_column :tests, :l3poi, TrueClass
    end
end
