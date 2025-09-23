require 'entities/envelope_event'

module API
  module V1
    # Envelope events
    module EnvelopeEvents
      def self.included(base) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
        base.instance_eval do
          resource :events do
            desc 'Retrieves envelope events'
            params do
              optional :after, type: DateTime
              optional :ctid, type: String
              optional :event, type: String, values: %w[create update destroy]
              optional :provisional,
                       default: 'include',
                       values: %w[exclude include only],
                       desc: 'Whether to include provisional records',
                       documentation: { param_type: 'query' }
              use :pagination
            end
            get do
              events = current_community
                       .versions
                       .with_provisional_publication_status(params[:provisional])
                       .where(item_type: 'Envelope')
                       .order(created_at: :desc)
              events.where!('created_at >= ?', params[:after]) if params[:after]
              events.where!(envelope_ceterms_ctid: params[:ctid]) if params[:ctid]
              events.where!(event: params[:event]) if params[:event]
              present paginate(events), with: API::Entities::EnvelopeEvent
            end
          end
        end
      end
    end
  end
end
