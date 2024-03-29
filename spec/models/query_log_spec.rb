require 'query_log'

RSpec.describe QueryLog, type: :model do
  describe '.start' do
    it 'initializes an instance with params and start time' do
      ctdl = { "Query" => { "@type" => "ceterms:Certificate", "ceterms:name" => "accounting" } }
      query_log = QueryLog.start(
        engine: 'ctdl',
        ctdl: ctdl
      )
      expect(query_log.started_at).not_to be_nil
      expect(query_log.completed_at).to be_nil
      expect(query_log.engine).to eq('ctdl')
      expect(query_log.ctdl).to eq(ctdl.to_json)
      expect(query_log.persisted?).to be true
    end
  end

  describe '#complete' do
    it 'updates the completed time' do
      query_log = QueryLog.start(
        engine: 'ctdl',
        ctdl: { "Query" => { "@type" => "ceterms:Certificate", "ceterms:name" => "accounting" } }
      )
      expect(query_log.completed_at).to be_nil
      query_log.complete({ result: [] })
      query_log.reload
      expect(query_log.completed_at).not_to be_nil
      expect(query_log.persisted?).to be true
    end
  end

  describe '#fail' do
    it 'updates the completed time and error' do
      query_log = QueryLog.start(
        engine: 'ctdl',
        ctdl: { "Query" => { "@type" => "ceterms:Certificate", "ceterms:name" => "accounting" } }
      )
      expect(query_log.completed_at).to be_nil
      expect(query_log.error).to be_nil
      query_log.fail(StandardError.new("Unexpected error").message)
      query_log.reload
      expect(query_log.completed_at).not_to be_nil
      expect(query_log.error).to eq("Unexpected error")
      expect(query_log.persisted?).to be true
    end
  end

  describe '#ctdl=, #result=, #query_logic=' do
    it "doesn't set a value if value is nil" do
      query_log = QueryLog.new
      %i(ctdl result query_logic).each do |method|
        query_log.send("#{method}=", nil)
        expect(query_log.send(method)).to eq(nil)
      end
    end

    it "sets a JSON-encoded value" do
      query_log = QueryLog.new
      %i(ctdl result query_logic).each do |method|
        query_log.send("#{method}=", { test: "test" })
        expect(query_log.send(method)).to eq("{\"test\":\"test\"}")
      end
    end
  end
end
