require 'envelope_dumps/envelope_builder'
require 'envelope_dumps/graph_builder'

# Builds an envelope community's download according to its type
class DownloadEnvelopes
  attr_reader :envelope_download, :last_dumped_at

  def initialize(envelope_download)
    @envelope_download = envelope_download
    @last_dumped_at = envelope_download.started_at unless envelope_download.with_error?
  end

  def self.call(envelope_download:)
    new(envelope_download).run
  end

  def builder
    builder_class =
      case envelope_download.type
      when 'envelope'
        EnvelopeDumps::EnvelopeBuilder
      when 'graph'
        EnvelopeDumps::GraphBuilder
      else
        raise "No dump builder is defined for `#{envelope_download.type}`"
      end

    builder_class.new(envelope_download, last_dumped_at)
  end

  def run # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    envelope_download.update!(
      internal_error_backtrace: [],
      internal_error_message: nil,
      started_at: Time.current,
      status: :in_progress
    )

    envelope_download.with_lock do
      envelope_download.status = :finished
      envelope_download.url = builder.run
    rescue StandardError => e
      Airbrake.notify(e)
      envelope_download&.internal_error_backtrace = e.backtrace
      envelope_download&.internal_error_message = e.message
      envelope_download.status = :failed
    ensure
      envelope_download.update!(finished_at: Time.current)
    end
  end
end
