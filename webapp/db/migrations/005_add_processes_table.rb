Sequel.migration do
    change do
        create_table :processes do
            primary_key :id
            String :tag
            String :status
            DateTime :started
            DateTime :stopped
        end
    end
end
