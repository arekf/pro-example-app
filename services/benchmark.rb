class Front::Services::Benchmark < Service

  def perform(data)
    sleep(1)
    reply sid: data['sid'], data: { event: "benchmarked!" }
  end

end
