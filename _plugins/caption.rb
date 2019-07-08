module Jekyll
    class CaptionBlockTag < Liquid::Block
        def initialize(tag_name, classes, tokens)
            super
            @caption_classes = classes
        end

        def render(context)
            site = context.registers[:site]
            converter = site.find_converter_instance(Jekyll::Converters::Markdown)
            content = converter.convert(super.strip)
            "<div class='caption'>#{content}</div>".strip
        end
    end
end

Liquid::Template.register_tag('caption', Jekyll::CaptionBlockTag)
