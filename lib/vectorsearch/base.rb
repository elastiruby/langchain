# frozen_string_literal: true

require "forwardable"

module Vectorsearch
  class Base
    extend Forwardable

    attr_reader :client, :index_name, :llm, :llm_api_key, :llm_client

    DEFAULT_METRIC = "cosine"

    # @param llm [Symbol] The LLM to use
    # @param llm_api_key [String] The API key for the LLM
    def initialize(llm:, llm_api_key:)
      LLM::Base.validate_llm!(llm: llm)

      @llm = llm
      @llm_api_key = llm_api_key

      @llm_client = LLM.const_get(LLM::Base::LLMS.fetch(llm)).new(api_key: llm_api_key)

      @loaders = Langchain.default_loaders
    end

    # Method supported by Vectorsearch DB to create a default schema
    def create_default_schema
      raise NotImplementedError, "#{self.class.name} does not support creating a default schema"
    end

    # Method supported by Vectorsearch DB to add a list of texts to the index
    def add_texts(...)
      raise NotImplementedError, "#{self.class.name} does not support adding texts"
    end

    # Method supported by Vectorsearch DB to search for similar texts in the index
    def similarity_search(...)
      raise NotImplementedError, "#{self.class.name} does not support similarity search"
    end

    # Method supported by Vectorsearch DB to search for similar texts in the index by the passed in vector.
    # You must generate your own vector using the same LLM that generated the embeddings stored in the Vectorsearch DB.
    def similarity_search_by_vector(...)
      raise NotImplementedError, "#{self.class.name} does not support similarity search by vector"
    end

    # Method supported by Vectorsearch DB to answer a question given a context (data) pulled from your Vectorsearch DB.
    def ask(...)
      raise NotImplementedError, "#{self.class.name} does not support asking questions"
    end

    def_delegators :llm_client,
      :default_dimension

    def generate_prompt(question:, context:)
      prompt_template = Prompt::FewShotPromptTemplate.new(
        prefix: "Context:",
        suffix: "---\nQuestion: {question}\n---\nAnswer:",
        example_prompt: Prompt::PromptTemplate.new(
          template: "{context}",
          input_variables: ["context"]
        ),
        examples: [
          {context: context}
        ],
        input_variables: ["question"],
        example_separator: "\n"
      )

      prompt_template.format(question: question)
    end

    def add_data(path: nil, paths: nil)
      raise ArgumentError, "Either path or paths must be provided" if path.nil? && paths.nil?
      raise ArgumentError, "Either path or paths must be provided, not both" if !path.nil? && !paths.nil?

      texts =
        Loader
          .with(*loaders)
          .load(path || paths)

      add_texts(texts: texts)
    end

    attr_reader :loaders

    def add_loader(*loaders)
      loaders.each { |loader| @loaders << loader }
    end
  end
end
