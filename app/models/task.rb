class Task < ApplicationRecord
  has_many :uploads, foreign_key: :task_id, primary_key: :task_id

  TOOLS = %w[compress resize rotate convert crop exif exif_edit].freeze
  STATUSES = %w[pending processing done failed].freeze

  BATCH_LIMIT_FREE = 20
  BATCH_LIMIT_PRO  = 100

  SINGLE_FILE_TOOLS = %w[crop rotate exif_edit].freeze

  def self.batch_limit_for(user, tool: nil)
    return 1 if SINGLE_FILE_TOOLS.include?(tool.to_s)
    user&.subscribed? ? BATCH_LIMIT_PRO : BATCH_LIMIT_FREE
  end
end
