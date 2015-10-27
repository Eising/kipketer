class Hastighedstest < Sinatra::Base

    # @!group Schedule controller
    
    # @method get_index
    # Shows all tests scheduled
    # @note This is the front page
    get '/' do
        @pagename = "schedule_index"
        @pagetitle = "All Tests"
        page = params.fetch("page", 1).to_i
        if params[:crid] =~ /(N[A-Z]{2}-\d{6})/i
            @tests = Tests.exclude(:deleted => true).exclude(:rfs => true).where(:crid => $1.upcase).paginate(page, 25)
            if @tests.count == 0
                flash[:notice] = "No results found."
                redirect to("/")
            end
        elsif not params[:crid].nil?
            flash[:notice] = "No results found."
            redirect to("/")

        else
            @tests = Tests.exclude(:deleted => true).exclude(:rfs => true).order(Sequel.desc(:id)).paginate(page, 20)
        end

        haml :'scheduling/index'

    end

    # @method get_schedule
    # Schedule a new test
    get '/schedule' do
        @pagename = "schedule"
        @pagetitle = "Schedule new test"
        @forms = Forms.exclude(:deleted => true).exclude(:inconsistent => true).all

        haml :'scheduling/schedule'
    end

    # @method get_schedule_embed
    # Schedule a new test
    # @note This is intended to be embedded in BackOffice as an iframe.
    get '/schedule/embed' do
        @embed = true

        @pagename = "schedule"
        @pagetitle = "Schedule new test"
        @forms = Forms.exclude(:deleted => true).exclude(:inconsistent => true)
        if params[:crid] =~ /^N[A-Z]{2}-\d{6}$/
            @crid = params[:crid]
        end
        if params[:customer]
            @customer = params[:customer]
        end
        if params[:location]
            @location = params[:location]
        end
        if params[:speed] =~ /^\d+$/
            @speed = params[:speed]
        end
        if @embed
            haml :'scheduling/embed/schedule'
        else
            haml :'scheduling/schedule'
        end

    end



    # @method post_schedule_config
    # Configure test
    post '/schedule/config' do
        @pagename = "schedule_config"
        @pagetitle = "Configure test"
        @crid = params[:bo_CRID]
        @customer = params[:bo_FullCompanyName]
        @location = params[:bo_LocationAFullName]
        @speed = params[:"bo_CPE.CPEConnectionSpeed"]
        @form_id = params[:form_id]
        @deadline = params[:"BO_ContractDeliveryDate"]
        if params[:request_id]
            @req = Requests.where(:id => params[:request_id])
            if not @req.count == 1
                halt 404
            end
            @req = @req.first
        end

        if params[:embed] == "true"
            @embed = true
        end
        validators = settings.validators
        form = Forms.where(:id => params[:form_id]).first
        defaults = JSON.parse(form.defaults)
        # Other tags
        all_cpe_tags = get_configurable_tags(form[:cpe_template_id])
        all_backbone_tags = get_configurable_tags(form[:backbone_template_id])
        all_cpe_fields = JSON.parse(form.cpe_template.fields)
        all_backbone_fields = JSON.parse(form.backbone_template.fields)


        all_cpe_tags.each do |tag| 
            unless defaults.has_key? tag
                defaults[tag] = {}
            end
            if all_cpe_fields.has_key? tag
                next if all_cpe_fields[tag] == "none"
                defaults[tag][:klass] = validators[all_cpe_fields[tag]][:class]
            end
        end
        all_backbone_tags.each do |tag|
            unless defaults.has_key? tag
                defaults[tag] = {}
            end
            if all_backbone_fields.has_key? tag
                next if all_backbone_fields[tag] == "none"
                defaults[tag][:klass] = validators[all_backbone_fields[tag]][:class]
            end
        end

        @defaults = defaults
        if @embed
            haml :'scheduling/embed/config'
        else
            haml :'scheduling/config'
        end
    end

    # @method post_schedule
    # Collect form elements for the scheduled test
    # @todo Sanitize input
    post '/schedule' do
        # collect form elements
        # TODO: sanitize input
        template_fields = {}
        params.each do |param, value|
            vars = %w(deadline crid customer location speed form_id submit embed)
            next if vars.include? param
            name = param.gsub('.', '__')
            template_fields[name] = value
        end
        deadline = Date.strptime(params[:deadline], '%d-%m-%Y')
        test = Tests.create(:template_fields => template_fields.to_json, :crid => params[:crid], :customer => params[:customer], :location => params[:location], :speed => params[:speed], :form_id => params[:form_id], :deadline => deadline, :timestamp => Time.now)
        flash[:notice] = "Created test with ID #{test.id}"
        if params[:embed] == "true"
            redirect to("/schedule/embedview/#{test.id}")
        else
            redirect to("/")
        end
    end

    # @method get_schedule_embedview
    # View test details
    # @note Uses the embedded BackOffice stylesheet
    get '/schedule/embedview/:id' do
        @pagename = "test_embedview"
        @pagetitle = "Test details"

        id = params[:id]

        @test = Tests.where(:id => id)
        if not @test.count == 1
            halt 404
        end
        @test = @test.first
        @template_fields = JSON.parse(@test.template_fields)
        @test_id = id
        @embed = true

        haml :'scheduling/embed/view'

    end


    # @method get_schedule_delete
    # Deletes a scheduled test
    # @param id [Integer] Id of scheduled test
    get '/schedule/delete/:id' do
        id = params[:id]
        test = Tests.where(:id => id)
        if test.count == 1
            test.update(:deleted => true)
            flash[:notice] = "Deleted test ##{id}"
            redirect to("/")
        else
            raise Sinatra::NotFound
        end
    end

end
