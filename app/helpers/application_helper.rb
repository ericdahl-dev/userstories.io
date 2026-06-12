module ApplicationHelper
  DEFAULT_META_DESCRIPTION = "Share a link for stakeholder feedback. Triage submissions and create GitHub issues when you accept.".freeze
  DEFAULT_OG_IMAGE_PATH = "/social-card.png".freeze

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

  def page_title
    content_for(:og_title).presence || content_for(:title).presence || default_page_title
  end

  def page_meta_description
    content_for(:og_description).presence || content_for(:meta_description).presence || default_meta_description
  end

  def page_meta_url
    explicit_url = content_for(:og_url).presence
    return absolute_meta_url(explicit_url) if explicit_url

    request.original_url
  end

  def page_meta_image_url
    absolute_meta_url(content_for(:og_image).presence || DEFAULT_OG_IMAGE_PATH)
  end

  def page_meta_image_alt
    content_for(:og_image_alt).presence || page_title
  end

  def page_twitter_card
    content_for(:twitter_card).presence || "summary_large_image"
  end

  private

  def default_page_title
    return "#{@project.name} - userstories.io" if defined?(@project) && @project.present?

    "userstories.io"
  end

  def default_meta_description
    return "Submit feedback for #{@project.name} on userstories.io. Share stories without a GitHub account." if defined?(@project) && @project.present?

    DEFAULT_META_DESCRIPTION
  end

  def absolute_meta_url(path_or_url)
    return path_or_url if path_or_url.to_s.match?(%r{\Ahttps?://}i)

    path = path_or_url.to_s.start_with?("/") ? path_or_url.to_s : "/#{path_or_url}"
    "#{request.base_url}#{path}"
  end
end
