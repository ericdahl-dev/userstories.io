module ApplicationHelper
  def render_refinement_markdown(text)
    html = text.to_s.dup
    html.gsub!(/^## (.+)$/, '<h3 class="mt-4 mb-2 text-sm font-semibold text-stone-900 dark:text-stone-100">\1</h3>')
    html.gsub!(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
    html.gsub!(/^- (.+)$/, '<li class="ml-4 list-disc">\1</li>')
    html.gsub!(/(<li[^>]*>.*<\/li>\n?)+/) do |list|
      "<ul class=\"my-2 space-y-1 text-sm\">#{list}</ul>"
    end
    simple_format(html, {}, sanitize: false)
  end

  def refinement_reply_counter(submission)
    remaining = submission.refinement_replies_remaining
    case remaining
    when 2 then "2 replies remaining"
    when 1 then "1 reply remaining"
    else "No replies left"
    end
  end
end
