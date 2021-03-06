# encoding: UTF-8

require File.expand_path("./helper", File.dirname(__FILE__))
require "redis/distributed"

setup do
  log = StringIO.new
  init Redis::Distributed.new(NODES, :logger => ::Logger.new(log))
end

test "INFO" do |r|
  %w(last_save_time redis_version total_connections_received connected_clients total_commands_processed connected_slaves uptime_in_seconds used_memory uptime_in_days changes_since_last_save).each do |x|
    r.info.each do |info|
      assert info.keys.include?(x)
    end
  end
end

test "INFO COMMANDSTATS" do |r|
  # Only available on Redis >= 2.9.0
  next if version(r) < 209000

  r.nodes.each { |n| n.config(:resetstat) }
  r.ping # Executed on every node

  r.info(:commandstats).each do |info|
    assert "1" == info["ping"]["calls"]
  end
end

test "MONITOR" do |r|
  begin
    r.monitor
  rescue Exception => ex
  ensure
    assert ex.kind_of?(NotImplementedError)
  end
end

test "ECHO" do |r|
  assert ["foo bar baz\n"] == r.echo("foo bar baz\n")
end

test "TIME" do |r|
  next if version(r) < 205040

  # Test that the difference between the time that Ruby reports and the time
  # that Redis reports is minimal (prevents the test from being racy).
  r.time.each do |rv|
    redis_usec = rv[0] * 1_000_000 + rv[1]
    ruby_usec = Integer(Time.now.to_f * 1_000_000)

    assert 500_000 > (ruby_usec - redis_usec).abs
  end
end
