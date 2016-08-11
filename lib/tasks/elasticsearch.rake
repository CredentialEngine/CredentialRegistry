namespace :es do
  desc 'Reset Index'
  task reset: :environment do
    if repo.index_exists?
      puts "Deleting Index: #{repo.index}"
      repo.delete_index!
    end

    puts "Creating Index: #{repo.index}"
    repo.create_index!
  end

  desc 'Load index'
  task load: :environment do
    repo.create_index!

    index_all
  end

  def repo
    @repo ||= Search::Repository.new
  end

  def index_all
    pbar = ProgressBar.create title: 'Indexing', total: Envelope.count

    Envelope.find_in_batches do |group|
      group.each do |item|
        Search::Document.build(item).index!
        pbar.increment
      end
    end
    pbar.finish
  end
end
