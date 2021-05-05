module Internal
  class EventsController < ::InternalController
    layout "internal"
    before_action :authorize_publisher, only: %i[approve]
    helper_method :event_type_name

    DEFAULT_EVENT_TYPE = "provider".freeze

    def index
      @event_type = determine_event_type(params[:event_type])

      load_pending_events(@event_type)
      @no_results = @events.blank?

      @success = params[:success]
      @pending = params[:success] == "pending"
    end

    def show
      @event = GetIntoTeachingApiClient::TeachingEventsApi.new.get_teaching_event(params[:id])
      raise_not_found unless @event.status_id == pending_event_status_id

      @page_title = @event.name
    end

    def new
      @event_type = determine_event_type(params[:event_type])
      @event = Event.new(venue_type: Event::VENUE_TYPES[:existing], type_id: @event_type)
      @event.building = EventBuilding.new
      if params[:duplicate]
        @event = get_event_by_id(params[:duplicate])
        @event.id = nil
        @event.readable_id = nil
      else
        @event = Event.new(venue_type: Event::VENUE_TYPES[:existing])
        @event.building = EventBuilding.new
      end
    end

    def approve
      api_event = GetIntoTeachingApiClient::TeachingEventsApi.new.get_teaching_event(params[:id])
      api_event.status_id = GetIntoTeachingApiClient::Constants::EVENT_STATUS["Open"]
      GetIntoTeachingApiClient::TeachingEventsApi.new.upsert_teaching_event(api_event)
      redirect_to internal_events_path(success: true)
    end

    def create
      @event = Event.new(event_params)
      @event.assign_building(building_params) unless @event.online_event?

      if @event.save
        redirect_to internal_events_path(success: :pending)
      else
        render action: :new
      end
    end

    def edit
      @event = get_event_by_id(params[:id])

      render :new
    end

  private

    def determine_event_type(type)
      event_types[type] || event_types[:provider]
    end

    def event_type_name
      params[:event_type] || DEFAULT_EVENT_TYPE
    end

    def get_event_by_id(event_id)
      api_event = GetIntoTeachingApiClient::TeachingEventsApi.new.get_teaching_event(event_id)
      @event = Event.initialize_with_api_event(api_event)
    end

    def authorize_publisher
      render_forbidden unless publisher?
    end

    def load_pending_events(event_type)
      search_results = GetIntoTeachingApiClient::TeachingEventsApi
                         .new
                         .search_teaching_events_grouped_by_type(
                           events_search_params(event_type),
                         )

      @group_presenter = Events::GroupPresenter.new(search_results)
      @events = @group_presenter.paginated_events_of_type(
        GetIntoTeachingApiClient::Constants::EVENT_TYPES["School or University event"],
        params[:page],
      )
    end

    def events_search_params(event_type)
      {
        type_id: event_type,
        status_ids: [pending_event_status_id],
        quantity_per_type: 1_000,
      }
    end

    def pending_event_status_id
      GetIntoTeachingApiClient::Constants::EVENT_STATUS["Pending"]
    end

    def event_types
      {
        provider: GetIntoTeachingApiClient::Constants::EVENT_TYPES["School or University event"],
        online: GetIntoTeachingApiClient::Constants::EVENT_TYPES["Online event"],
      }
        .with_indifferent_access
        .freeze
    end

    def event_params
      params.require(:internal_event).permit(
        :id,
        :name,
        :readable_id,
        :summary,
        :description,
        :is_online,
        :start_at,
        :end_at,
        :provider_contact_email,
        :provider_organiser,
        :provider_target_audience,
        :provider_website_url,
        :venue_type,
        :type_id,
        :scribble_id,
      )
    end

    def building_params
      params.require(:internal_event).require(:building).permit(
        :id,
        :venue,
        :address_line1,
        :address_line2,
        :address_line3,
        :address_city,
        :address_postcode,
      )
    end
  end
end
