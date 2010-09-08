class TwitterStatus
  attr_accessor :text,:created_at
  def initialize(text,created_at)
    @text = text
    @created_at = created_at
  end
end
