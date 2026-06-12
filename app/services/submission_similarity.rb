class SubmissionSimilarity
  DUPLICATE_THRESHOLD = 0.55
  RELATED_THRESHOLD = 0.30

  STOP_WORDS = %w[
    a an the and or but for to of in on at by with from as is are was were be been being
    i me my we our you your they their it its this that these those am is are was were
    want need user story add implement support feature enable allow create update delete
    get make use can should would could will has have had do does did not no yes so
  ].freeze

  def self.score(source_title, source_body, other_title, other_body)
    title_score = jaccard(normalize(source_title), normalize(other_title))
    body_score = jaccard(normalize(source_body), normalize(other_body))
    combined_score = jaccard(
      normalize("#{source_title} #{source_body}"),
      normalize("#{other_title} #{other_body}")
    )

    [ title_score * 0.55 + body_score * 0.25 + combined_score * 0.20, title_score ].max
  end

  def self.jaccard(left, right)
    left_tokens = token_set(left)
    right_tokens = token_set(right)
    return 0.0 if left_tokens.empty? && right_tokens.empty?

    intersection = (left_tokens & right_tokens).size
    union = (left_tokens | right_tokens).size
    intersection.to_f / union
  end

  def self.normalize(text)
    text.to_s.downcase.gsub(/[^\w\s]/, " ").squeeze(" ").strip
  end

  def self.token_set(text)
    normalize(text).split.reject { |token| STOP_WORDS.include?(token) || token.length < 2 }.to_set
  end

  private_class_method :jaccard, :normalize, :token_set
end
