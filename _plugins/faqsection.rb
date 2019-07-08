module Jekyll
    class FAQSectionBlockTag < Liquid::Block
        def initialize(tag_name, names, tokens)
            super
            names = names.split('|')
            @name = names[0]
            if names.length >= 2
                @alt_name = names[1]
            else
                @alt_name = @name
            end
        end

        def render(context)
            site = context.registers[:site]
            converter = site.find_converter_instance(Jekyll::Converters::Markdown)
            content = converter.convert(super.strip)
          "<div class='faqsection'><h1 data-alt='#{@name}'>#{@alt_name}</h1>#{content}</div>".strip
        end
    end
end

Liquid::Template.register_tag('faqsection', Jekyll::FAQSectionBlockTag)
