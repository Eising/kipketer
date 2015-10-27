Sequel.migration do
    change do
        add_column :templates, :contents_deconfigure, String, :text => true
    end
end
