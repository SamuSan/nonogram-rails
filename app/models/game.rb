class Game < ActiveRecord::Base
  MIN_PLAYERS = 2

  # t.datetime  :time_started
  # t.datetime  :time_finished
  # t.integer   :nonogram_id
  # t.index     :nonogram_id

  belongs_to  :nonogram
  has_many    :players, dependent: :destroy

  validates   :nonogram, presence: true, if: :started?

  scope       :not_completed, -> { where(time_finished: nil) }
  scope       :completed, -> { where.not(time_finished: nil) }

  def self.finished(nonogram)
    self.where('nonogram_id is ?', nonogram.id)
  end

  def ready_to_play?
    # if just display logic move into helper
    players.length >= MIN_PLAYERS unless started?
  end

  def started?
    time_started.present?
  end

  def completed?
    started? && time_finished.present?
  end

  def seconds_taken_to_complete
    time_finished - time_started if completed?
  end
end