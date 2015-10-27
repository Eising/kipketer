Sequel.migration do
    change do
       add_column :results, :protocol, String
    end
end
