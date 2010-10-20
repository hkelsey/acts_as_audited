module CollectiveIdea #:nodoc:
  module ActionController #:nodoc:
    module Audited #:nodoc:
      def audit(*models)
        ActiveSupport::Deprecation.warn("#audit is deprecated. Declare #acts_as_audited in your models.", caller)
        
        options = models.extract_options!

        # Parse the options hash looking for classes
        options.each_key do |key|
          models << [key, options.delete(key)] if key.is_a?(Class)
        end

        models.each do |(model, model_options)|
          model.send :acts_as_audited, model_options || {}
        end
      end
    end
  end
end

class AuditSweeper < ActionController::Caching::Sweeper #:nodoc:
  observe Audit
  def before_create(audit)
    audit.user ||= acts_as_audited_user
  end

  def acts_as_audited_user
    if controller.respond_to?(:acts_as_audited_user, true)
      controller.send :acts_as_audited_user
    elsif controller.respond_to?(:current_user, true)
      controller.send :current_user
    end
  end
end

ActionController::Base.class_eval do
  extend CollectiveIdea::ActionController::Audited
  cache_sweeper :audit_sweeper
end
Audit.add_observer(AuditSweeper.instance)
