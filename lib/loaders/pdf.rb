module Loaders
  class PDF < Base
    #
    # This Loader parses PDF files into text.
    # If you'd like to use it directly you can do so like this:
    # Loaders::PDF.new("path/to/my.pdf").load
    #
    # This parser is also invoked when you're adding data to a Vectorsearch DB:
    # qdrant = Vectorsearch::Qdrant.new(...)
    # path = Langchain.root.join("path/to/my.pdf")
    # qdrant.add_data(path: path)
    #

    def initialize(path)
      depends_on "pdf-reader"
      require "pdf-reader"

      @path = path
    end

    # Check that the file is a PDF file
    def loadable?
      @path.to_s.end_with?(".pdf")
    end

    def load
      ::PDF::Reader
        .new(@path)
        .pages
        .map(&:text)
        .join("\n\n")
    end
  end
end
