module CallsToAction
  class ChatOnlineComponent < ViewComponent::Base
    attr_accessor :title, :text, :button_text, :heading_tag

    def initialize(title: default_title, text: default_text, heading_tag: "h2")
      super

      @title       = title
      @text        = text
      @heading_tag = heading_tag
    end

    def icon
      image_pack_tag("media/images/icon-question.svg",
                     width: 50,
                     height: 50,
                     alt: "",
                     class: "call-to-action__icon")
    end

  private

    def default_title
      "Chat to us"
    end

    def default_text
      "If you're unsure whether your qualifications are equivalent, you can chat to us."
    end
  end
end
