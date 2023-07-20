require 'active_record/connection_adapters/postgresql_adapter'

# https://dalibornasevic.com/posts/77-auto-reconnect-for-activerecord-connections
module PostgreSQLAdapterReconnect
  QUERY_EXCEPTIONS = [
    'SSL connection has been closed unexpectedly',
    'server closed the connection unexpectedly',
    'no connection to the server',
  ].freeze

  CONNECTION_EXCEPTIONS = [
    'connection is closed',
    'could not connect to server',
    'the database system is starting up',
  ].freeze

  def exec_query(sql, name = 'SQL', binds = [], prepare: false)
    super(sql, name, binds, prepare: prepare)
  rescue ActiveRecord::StatementInvalid => e
    raise unless recoverable_query?(e.message)

    in_transaction = transaction_manager.current_transaction.open?
    try_reconnect
    in_transaction ? raise : retry
  end

  private

  def recoverable_query?(error_message)
    QUERY_EXCEPTIONS.any? { |e| error_message.include?(e) }
  end

  def recoverable_connection?(error_message)
    CONNECTION_EXCEPTIONS.any? { |e| error_message.include?(e) }
  end

  def try_reconnect
    sleep_times = [0.1, 0.5, 1, 2, 4, 8, 16, 32]

    begin
      reconnect!
    rescue PG::Error => e
      sleep_time = sleep_times.shift

      if sleep_time && recoverable_connection?(e.message)
        logger&.warn("DB Server timed out, retrying in #{sleep_time} sec")
        sleep(sleep_time)
        retry
      else
        logger&.error(e)
        raise
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterReconnect)
