module KnifeProfitbricks
  module Extension
    module Profitbricks
      module WaitFor
        MAX_RETRIES = 15

        def self.extended(base)
          base.class_eval do
            class << self
              alias wait_for_without_retry wait_for
              alias wait_for wait_for_with_retry
            end
          end
        end

        def wait_for_with_retry(*args, &block)
          retries = 0

          begin
            wait_for_without_retry *args, &block
          rescue Exception => e
            if e.message.include?('wait_for timeout') && retries < MAX_RETRIES
              retries += 1
              print "***** retry wait_for - #{retries} / #{MAX_RETRIES} *****\n"
              retry
            else
              raise e
            end
          end
        end
      end
    end
  end
end

ProfitBricks.send :extend, KnifeProfitbricks::Extension::Profitbricks::WaitFor
