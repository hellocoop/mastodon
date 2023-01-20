# frozen_string_literal: true

class Hello::TwitterTimelineScheduler
  include Sidekiq::Worker

  sidekiq_options retry: 0, lock: :until_executed

  def perform
    Rails.logger.info 'Performing Scheduled Twitter Timeline...'
    Hello::TwitterTimeline.fetch_timeline
  end
end
