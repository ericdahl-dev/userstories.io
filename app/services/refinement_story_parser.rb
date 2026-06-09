module RefinementStoryParser
  REFINED_STORY_PATTERN = /
    \#\#\s*Refined\ story\s*\n
    \*\*Title:\*\*\s*(?<title>.+?)\s*\n
    \*\*Details:\*\*\s*(?<body>.+?)(?:\n\#\#|\z)
  /mx

  module_function

  def parse(markdown)
    match = markdown.match(REFINED_STORY_PATTERN)
    return nil unless match

    {
      title: match[:title].strip,
      body: match[:body].strip
    }
  end
end
