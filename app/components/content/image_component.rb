module Content
  class ImageComponent < ViewComponent::Base
    attr_reader :path

    def initialize(path:)
      super

      @path = path
    end

    def render?
      path.present?
    end

    def call
      helpers.image_pack_tag(*helpers.image_args(path))
    end
  end
end
