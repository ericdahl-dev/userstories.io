class Collaborator < ApplicationRecord
  ADJECTIVES = %w[
    swift brave calm dark eager fair glad keen lean mild neat
    neat odd pale pure quiet rare safe tame vast warm wise zany
    bold cold damp dull fond gold hard icy jade kind lazy lush
    mute nice open pink rosy sage teal umber vivid waxy young
  ].freeze

  NOUNS = %w[
    penguin falcon badger otter hedgehog panda koala lynx crane ibis
    raven bison gecko finch moose quail stoat viper wren yak zebra
    bream carp dace dove egret frog gull hare kite loon mink newt
    pigeon robin snipe stork swift teal thrush vole wagtail weasel
  ].freeze

  has_many :submissions, dependent: :destroy
  has_many :projects, through: :submissions
  has_many :magic_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  normalizes :email, with: ->(e) { e.strip.downcase }

  def self.generate_handle
    loop do
      handle = "#{ADJECTIVES.sample}-#{NOUNS.sample}-#{rand(10..99)}"
      return handle unless exists?(name: handle)
    end
  end

  def self.for_login(email:)
    email = email.to_s.strip.downcase
    record = find_or_initialize_by(email: email)
    record.name = generate_handle if record.name.blank?
    record.save!
    record
  end
end
