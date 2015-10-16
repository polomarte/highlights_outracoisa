class EditionDeadlineNotificationJob
  def self.perform
    new.perform
  end

  def perform
    Edition.find_each do |edition|
      @edition = edition

      @lazy_participators =
        case Date.current + 2.days
        when @edition.prioritizing_ends_at
          @edition.prioritizators
          .joins('LEFT OUTER JOIN prioritizations ON prioritizations.participation_id = participations.id')
          .where('prioritizations.id IS NULL')
        when @edition.mapping_ends_at
          @edition.mappers.select{|mapper| !mapper.did_mapping?}
        when @edition.evaluating_ends_at
          @edition.evaluators.select{|evaluator| !evaluator.did_evaluations?}
        end

      notify if @lazy_participators.present?
    end

    Rails.logger.info 'Editions status updated!'
  end

private

  def notify
    @lazy_participators.each do |participation|
      args = [@edition.status, participation.user]
      NotificationMailer.edition_deadline(*args).deliver
    end
  end
end
