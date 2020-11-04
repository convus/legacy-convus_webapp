# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeParser do
  let(:subject) { TimeParser }
  before { Time.zone = subject::DEFAULT_TIMEZONE }

  describe "parse" do
    context "America/Los_Angeles" do
      let(:target_time) { 1454925600 }
      let(:time_str) { "2016-02-08 02:00:00" }
      it "parses with timezone, without and with unreadable timezones" do
        expect(subject.parse(time_str, "America/America/Los_Angeles").to_i).to eq target_time
        expect(subject.parse(time_str).to_i).to eq target_time
        expect(subject.parse(time_str, "America/PartyCity").to_i).to eq target_time
      end
    end
    context "time" do
      let(:time) { Time.current - 55.minutes }
      it "returns the time" do
        expect(subject.parse(time)).to be_within(1).of time
      end
    end
    context "UTC" do
      let(:target_time) { 1454814602 }
      let(:time_str) { "2016-02-07 03:10:02" }
      it "parses with UTC timezone and with a place in UTC" do
        expect(subject.parse(time_str, "UTC").to_i).to eq target_time
        expect(subject.parse(time_str, "Atlantic/Reykjavik").to_i).to eq target_time
        expect(subject.parse(time_str).to_i).to_not eq target_time
      end
    end
    context "nil" do
      it "returns nil" do
        expect(subject.parse(" ")).to be_nil
        expect(subject.parse(nil)).to be_nil
      end
    end
    context "with cray IE 11 time params" do
      let(:target_time) { 1538290800 }
      let(:target_time_in_uk) { 1538262000 }
      let(:time_str) { "09/30/2018" }
      it "parses it, resets the zone over and over again" do
        expect(Time.zone).to eq subject::DEFAULT_TIMEZONE
        expect(subject.parse(time_str, "").to_i).to eq target_time
        expect(Time.zone).to eq subject::DEFAULT_TIMEZONE
        expect(subject.parse(time_str, "Europe/London").to_i).to eq target_time_in_uk
        expect(Time.zone).to eq subject::DEFAULT_TIMEZONE
      end
    end
    context "2017-3" do
      let(:target_date) { Date.parse("2017-03-01") }
      it "parses out the beginning of the month" do
        expect(subject.parse("2017-3").to_date).to eq target_date
        expect(subject.parse("2017-03").to_date).to eq target_date
        expect(subject.parse("2017/03").to_date).to eq target_date
        # And all the reverse, for americans
        expect(subject.parse("3-2017").to_date).to eq target_date
        # TODO: make these two specs work
        # They doesn't actually work, they interprets without an ArgumentError and don't hit special formatting
        # expect(subject.parse("03-2017").to_date).to eq target_date
        # expect(subject.parse("03/2017").to_date).to eq target_date
      end
    end
  end

  describe "timezone_parser" do
    let(:timezone_str) { "America/New York" }
    let(:target_timezone) { ActiveSupport::TimeZone["Eastern Time (US & Canada)"] }
    it "returns correctly" do
      expect(subject.parse_timezone("")).to eq subject::DEFAULT_TIMEZONE
      expect(subject.parse_timezone(timezone_str).utc_offset).to eq target_timezone.utc_offset
      # Alternative timezone name
      expect(subject.parse_timezone("Eastern Time (US & Canada)").utc_offset).to eq target_timezone.utc_offset
    end
    context "LA" do
      let(:timezone_str) { "America/Los_Angeles" }
      let(:target_timezone) { ActiveSupport::TimeZone["America/Los_Angeles"] }
      it "returns correct timezone" do
        expect(subject.parse_timezone(timezone_str)).to eq target_timezone
      end
    end
  end
end
