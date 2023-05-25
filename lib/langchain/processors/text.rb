# frozen_string_literal: true

module Langchain
  module Processors
    class Text < Base
      EXTENSIONS = [".txt"]
      CONTENT_TYPES = ["text/plain"]

      def parse(data)
        data.read
      end
    end
  end
end
