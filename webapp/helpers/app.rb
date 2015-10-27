class Hastighedstest < Sinatra::Base
    not_found do
        @pagetitle = "Page not found"
        haml :notfound
    end

end
