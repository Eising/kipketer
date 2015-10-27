Sequel.migration do
    change do
        add_column :results, :image, String, :text => true
    end
end
