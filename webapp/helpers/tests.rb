class Hastighedstest < Sinatra::Base

    # Load the test configuration YAML file
    #
    # @return A Hash from YAML
    def test_config
        config = YAML.load_file("etc/tests.yml")
        config
    end

end
