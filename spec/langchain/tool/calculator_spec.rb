# frozen_string_literal: true

require "eqn"

RSpec.describe Langchain::Tool::Calculator do
  describe "#execute" do
    it "calculates the result" do
      expect(subject.execute(input: "2+2")).to eq(4)
    end

    it "calls Serp API when eqn throws an error" do
      allow(Eqn::Calculator).to receive(:calc).and_raise(Eqn::ParseError)

      expect(Langchain::Tool::SerpApi).to receive(:execute_search).with(input: "2+2").and_return({answer_box: {to: 4}})

      subject.execute(input: "2+2")
    end
  end
end
