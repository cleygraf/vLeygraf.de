# All files in the 'lib' directory will be loaded
# before nanoc starts compiling.
include Nanoc::Helpers::Rendering
include Nanoc3::Helpers::LinkTo
include Nanoc3::Helpers::Blogging

def previous_link
    if @item[:kind] == "article"
        prv = sorted_articles.index(@item) - 1
        if sorted_articles[prv].nil?
            return ""
        else
            link_to('&larr;', sorted_articles[prv].reps[0])
        end
    end
end

def next_link
    if @item[:kind] == "article"
        nxt = sorted_articles.index(@item) + 1
        if sorted_articles[nxt].nil?
            return ""
        else
        link_to('&rarr;', sorted_articles[nxt].reps.find { |r| r.name == :default })
        end
    end
end

module PostHelper

    def get_pretty_date(post)
        attribute_to_time(post[:created_at]).strftime('%B %-d, %Y')
    end

    def get_post_start(post)
      content = post.compiled_content
      if content =~ /<!--break-->/
        content = content.partition('<!--break-->').first +
        "<div class='read-more'><a href='#{post.path}'>weiter lesen &rsaquo;</a></div>"
      end
      return content
    end

end

include PostHelper