namespace :search do
  desc 'Reset Index'
  task reindex: :cer_environment do
    require 'services/extract_envelope_resources'

    pbar = ProgressBar.create title: 'Indexing', total: Envelope.not_deleted.count

    Envelope.not_deleted.find_in_batches do |group|
      group.each do |item|
        ExtractEnvelopeResources.call(envelope: item)
        pbar.increment
      end
    end
    pbar.finish
  end
end
