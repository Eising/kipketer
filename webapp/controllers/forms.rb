class Hastighedstest < Sinatra::Base
    # @!group Forms controller

    # @method get_forms
    # Get all forms
    get '/forms' do
        @pagename = "forms"
        @pagetitle = "Manage forms"

        @forms = Forms.exclude(:deleted => true).all

        haml :'forms/forms'
    end

    # @method get_forms_view
    # View forms
    get '/forms/view/:id' do
        @pagename = "forms_view"
        @pagetitle = "View forms"

        @form = Forms.where(:id => params[:id])
        if not @form.count == 1
            halt 404
        else
            @form = @form.first
        end

        haml :'forms/view'


    end


    # @method get_forms_compose
    # Compose form
    get '/forms/compose' do
        templates = Templates.exclude(:deleted => true).all
        @cpe_templates = []
        @bb_templates = []

        templates.each do |template|
            if template[:type] == "cpe"
                @cpe_templates << template
            else
                @bb_templates << template
            end
        end
        @pagename = "forms_compose"
        @pagetitle = "Manage forms"

        haml :'forms/compose'
    end

    # @macro [attach] sinatra.post
    #   @overload post "$1"
    # @method post_forms_config
    # Configure composed form
    post '/forms/config' do
        @defaults = {}
        @pagename = "forms_config"
        @pagetitle = "Configure form"
        @cpe_template_id = params[:cpe_template_id]
        @backbone_template_id = params[:backbone_template_id]
        cpe_tags = get_configurable_tags(@cpe_template_id)
        backbone_tags = get_configurable_tags(@backbone_template_id)
        @tags = cpe_tags | backbone_tags
        @name = params[:name]

        haml :'/forms/config'
    end


    # @method get_forms_update
    # Update an existing form
    get '/forms/update/:id' do
        id = params[:id]
        if not Forms.where(:id => id).count == 1
            halt 404
        end
        form = Forms.where(:id => id).first
        @cpe_template_id = form[:cpe_template_id]
        @backbone_template_id = form[:backbone_template_id]
        cpe_tags = get_configurable_tags(@cpe_template_id)
        backbone_tags = get_configurable_tags(@backbone_template_id)
        @tags = cpe_tags | backbone_tags
        @name = form[:name]
        @update = true
        @form_id = id
        @defaults = JSON.parse(form.defaults)

        haml :'/forms/config'
    end


    # @method post_forms_add
    # Submits a form
    post '/forms/add' do
        defaults = {}
        params.each do |param, value|
            if res = param.match(/^tag\.(.*)$/)
                defaults[res[1]] = {} unless defaults.has_key? res[1]
                defaults[res[1]][:value] = value 
            end
            if res = param.match(/^name\.(.*)$/)
                defaults[res[1]] = {} unless defaults.has_key? res[1]
                defaults[res[1]][:name] = value
            end
        end
        args = { 
            :cpe_template_id => params[:cpe_template_id], 
            :backbone_template_id => params[:backbone_template_id],
            :name => params[:name],
            :defaults => defaults.to_json,
            :inconsistent => nil
        }
        if params[:form_id]
            form = Forms.where(:id => params[:form_id])
            if form.count == 1
                form = form.first
                form.update(args)
                flash[:notice] = "updated form ##{form.id}"
            else
                halt 404
            end
        else
            form = Forms.create(args)
            flash[:notice] = "Added form ##{form.id}"
        end
        redirect to('/forms')
    end

    # @method get_forms_delete
    # Deletes a form
    # @param id [Integer] The form id to delete
    get '/forms/delete/:id' do

        # logic to delete id
        form = Forms.where(:id => params[:id])
        if form.count == 1
            form.update(:deleted => true)
            flash[:notice] = "Deleted form ##{params[:id]}"
            redirect to('/forms')
        else
            raise Sinatra::NotFound
        end
    end
        

end
