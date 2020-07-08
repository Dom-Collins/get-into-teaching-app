module GetIntoTeachingApi
  class Client
    include Singleton

    class << self
      delegate :upcoming_events, :search_events, :event, to: :instance
      delegate :event_types, to: :instance
    end

    def upcoming_events
      UpcomingEvents.new(**api_args).call
    end

    def search_events(**args)
      SearchEvents.new(**api_args.merge(args)).call
    end

    def event(event_id)
      Event.new(event_id: event_id, **api_args).call
    end

    def event_types
      EventTypes.new(**api_args).call
    end

  private

    def api_args
      { token: token, endpoint: endpoint }
    end

    def token
      ENV["GIT_API_TOKEN"].presence || \
        Rails.application.credentials.git_api_token
    end

    def endpoint
      ENV["GIT_API_ENDPOINT"].presence || \
        Rails.application.config.x.git_api_endpoint.presence
    end
  end
end
