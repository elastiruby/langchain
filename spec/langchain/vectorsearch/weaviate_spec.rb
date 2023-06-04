# frozen_string_literal: true

require "weaviate"

RSpec.describe Langchain::Vectorsearch::Weaviate do
  subject {
    described_class.new(
      url: "http://localhost:8080",
      api_key: "123",
      index_name: "products",
      llm: Langchain::LLM::OpenAI.new(api_key: "123")
    )
  }

  describe "#create_default_schema" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate_create_default_schema.json")) }

    before do
      allow_any_instance_of(Weaviate::Client).to receive_message_chain(:schema, :create).and_return(fixture)
    end

    it "creates the default schema" do
      expect(subject.create_default_schema).to eq(fixture)
    end
  end

  describe "#add_texts" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate_add_texts.json")) }

    before do
      allow_any_instance_of(
        Weaviate::Objects
      ).to receive(:batch_create)
        .with(
          objects: [{
            class: "products",
            properties: {content: "Hello World"},
            vector: [-0.0018150936, 0.0017554426, -0.022715086]
          }]
        )
        .and_return(fixture)

      allow_any_instance_of(
        ::OpenAI::Client
      ).to receive(:embeddings).and_return({
        "data" => [
          {
            "embedding" => [
              -0.0018150936,
              0.0017554426,
              -0.022715086
            ]
          }
        ]
      })
    end

    it "adds texts" do
      expect(subject.add_texts(texts: ["Hello World"])).to eq(fixture)
    end
  end

  describe "#similarity_search" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate_search.json")) }

    before do
      allow_any_instance_of(
        Weaviate::Query
      ).to receive(:get)
        .with(
          class_name: "products",
          near_vector: "{ vector: [-0.0018150936, 0.0017554426, -0.022715086] }",
          limit: "4",
          fields: "content _additional { id }"
        )
        .and_return(fixture)

      allow_any_instance_of(
        ::OpenAI::Client
      ).to receive(:embeddings).and_return({
        "data" => [
          {
            "embedding" => [
              -0.0018150936,
              0.0017554426,
              -0.022715086
            ]
          }
        ]
      })
    end

    it "searches for similar texts" do
      expect(subject.similarity_search(query: "earth")).to eq(fixture)
    end
  end

  describe "#similarity_search_by_vector" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate_search.json")) }

    before do
      allow_any_instance_of(
        Weaviate::Query
      ).to receive(:get)
        .with(
          class_name: "products",
          near_vector: "{ vector: [0.1, 0.2, 0.3] }",
          limit: "4",
          fields: "content _additional { id }"
        )
        .and_return(fixture)
    end

    it "searches for similar vectors" do
      expect(subject.similarity_search_by_vector(embedding: [0.1, 0.2, 0.3])).to eq(fixture)
    end
  end

  describe "#ask" do
    let(:matches) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate_search.json")) }
    let(:prompt) { "Context:\n#{matches[0]["content"]}\n---\nQuestion: #{question}\n---\nAnswer:" }
    let(:question) { "How many times is \"lorem\" mentioned in this text?" }
    let(:answer) { "5 times" }

    before do
      allow(subject).to receive(:similarity_search).with(
        query: question
      ).and_return(matches)
      allow(subject.llm).to receive(:chat).with(prompt: prompt).and_return(answer)
    end

    it "asks a question" do
      expect(subject.ask(question: question)).to eq(answer)
    end
  end
end
