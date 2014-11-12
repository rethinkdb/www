module Jekyll
    class APISectionBlockTag < Liquid::Block
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
            converter = site.getConverterImpl(Jekyll::Converters::Markdown)
            content = converter.convert(super.strip)
          "<div class='apisection'><h1 data-alt='#{@name}'>#{@alt_name}</h1>#{content}</div>".strip
        end
    end

    class APIBodyTag < Liquid::Block
        def initialize(tag_name, names, tokens)
            super
        end

        def render(context)
            site = context.registers[:site]
            converter = site.getConverterImpl(Jekyll::Converters::Markdown)
            content = "<p>#{super.gsub('<', '&lt;').gsub('>', '&gt;').strip.gsub(/\n([^\s])/, '</p><p>\1')}</p>"  #.gsub(/\n$/, '').gsub(/(?:\n\r?|\r\n?)/, '<br/>')
          "<div class='command-body'>#{content}</div>".strip

        end
    end

    class APIUrlTag < Liquid::Block
        def initialize(tag_name, params, tokens)
            super
            @lang = params.gsub(/ /, '')
        end

        def render(context)
            '/'+super.gsub(/python|javascript|ruby/, @lang)
        end
    end
end

Liquid::Template.register_tag('apisection', Jekyll::APISectionBlockTag)
Liquid::Template.register_tag('apibody', Jekyll::APIBodyTag)
Liquid::Template.register_tag('apiurltag', Jekyll::APIUrlTag)
