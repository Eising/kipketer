class Hastighedstest < Sinatra::Base
    #@!group Admin controller

    # @macro [attach] sinatra.get
    #   @overload get "$1"
    # @method get_admin
    # Shows admin page
    get '/admin' do
        @pagename = "admin"
        @pagetitle = "Administration"
        haml :'admin/index'
    end

    # @method get_admin_scheduling
    # Manage deleted schedules
    get '/admin/scheduling' do
        @pagetitle = "Manage deleted schedules"
        @pagename = "admin_scheduling"
        @tests = Tests.where(:deleted => true).or(:rfs => true).all
        haml :'admin/scheduling'
    end

    # @method get_admin_scheduling_undelete
    # Undeletes a deleted schedule
    # @param id [Integer] id to be undeleted
    get '/admin/scheduling/undelete/:id' do
        id = params[:id]
        test = Tests.where(:id => id)
        if test.count == 1
            if test.first.deleted
                test.update(:deleted => false)
            elsif test.first.rfs
                test.update(:rfs => false)
            end
            flash[:notice] = "Undeleted scheduled test ##{id}"
            redirect to("/admin/scheduling")
        else
            raise Sinatra::NotFound
        end

    end

    # @method get_admin_templates
    # Shows the admin/templates view
    get '/admin/templates' do
        @pagetitle = "Manage deleted templates"
        @pagename = "admin_templates"
        @templates = Templates.where(:deleted => true).all
        haml :'admin/templates'
    end

    # @method get_templates_undelete
    # Undeletes a deleted template
    # @param id [Integer] the id to undelete
    get '/admin/templates/undelete/:id' do
        id = params[:id]
        template = Templates.where(:id => id)
        if template.count == 1
            template.update(:deleted => false)
            flash[:notice] = "Undeleted template ##{id}"
            redirect to("/admin/templates")
        else
            raise Sinatra::NotFound
        end
    end

    # @method get_admin_forms
    # Get admin/forms
    get '/admin/forms' do
        @pagetitle = "Manage deleted forms"
        @pagename = "admin_forms"
        @forms = Forms.where(:deleted => true).all
        haml :'admin/forms'
    end

    # @method get_admim_forms_undelete
    # Undeletes a form
    # @param id [Integer] the id to undelete
    get '/admin/forms/undelete/:id' do
        id = params[:id]
        form = Forms.where(:id => id)
        if form.count == 1
            form.update(:deleted => false)
            flash[:notice] = "Undeleted form ##{id}"
            redirect to("/admin/forms")
        else
            raise Sinatra::NotFound
        end
    end

    # @method get_admin_results
    # Manage test results
    get '/admin/results' do
        @pagetitle = "Manage test results"
        @pagename = "admin_results"
        @tests = Tests.all
        haml :'admin/results'
    end

    # @method get_admin_results_purge
    # Purge all test results for a given test
    # @method id [Integer] the test id
    get '/admin/results/purge/:id' do
        id = params[:id]
        test = Tests.where(:id => id)
        if test.count == 1
            count = test.first.test_results_dataset.delete
            flash[:notice] = "Deleted #{count} results from ID #{id}"
            redirect to("/admin/results")
        else
            raise Sinatra::NotFound
        end
    end

    # @method get_admin_external
    # Manage external reports
    get '/admin/external' do
        @pagetitle = "Manage external reports"
        @pagename = "admin_external"
        @results = Results.where(:test_type => "external").all

        haml :'admin/external'
    end

    # @method get_admin_external_delete
    # Delete external report
    # @param id [Integer] the id to delete
    get '/admin/external/delete/:id' do
        id = params[:id]
        result = Results.where(:id => id)
        if not result.count == 1
            halt 404
        end
        res = JSON.parse(result.first.results)
        # Delete the file
        deleted = true
        begin
            File.delete(res["path"])
        rescue => e
            $stderr.puts e.inspect
            deleted = false
        end
        result.delete if deleted
        flash[:notice] = "Deleted external report"
        redirect to("/admin/external")
    end


    # @method get_admin_migrate
    # Migrate from old test system
    get '/admin/migrate' do
        # Migrate tests
        @pagename = "schedule"
        @requests = DB[:requests].where(:rfs => 0).all

        @pagetitle = "Migrate from old system"
        @pagename = "admin_migrate"

        haml :'admin/migrate'
    end

    # @method get_admin_migrate_id
    # Migrate a specific test
    # @param id [Integer] id in the old test database
    get '/admin/migrate/:id' do
        id = params[:id]
        req = Requests.where(:id => id)
        if req.count == 0
            halt 404
        end
        @req = req.first
        @forms = Forms.exclude(:deleted => true)
        
        haml :'admin/migrate_config'
        
    end






end





