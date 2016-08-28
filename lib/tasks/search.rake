namespace :search do
  desc 'Reset Index'
  task reindex: :environment do
    pbar = ProgressBar.create title: 'Indexing', total: Envelope.count

    Envelope.find_in_batches do |group|
      group.each do |item|
        item.set_fts_attrs
        item.save
        pbar.increment
      end
    end
    pbar.finish
  end
end
