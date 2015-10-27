Sequel.migration do
    change do
        create_table :results do
            primary_key :id
            String :results, :text => true
            Integer :test_id
            String :test_type
            DateTime :timestamp
        end
    end
end

