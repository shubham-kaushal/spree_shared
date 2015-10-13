module Apartment
  module Elevators
    # Provides a rack based db switching solution based on subdomains
    # Assumes that database name should match subdomain
    class Subdomain

      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        Rails.logger.error "  Requested URL: #{request.url}"
        database = subdomain(request)

        if database
          #switch database
          begin
            database.gsub! '-', '_'

            Apartment::Tenant.switch database

            Rails.logger.error "  Using database '#{database}'"

            #set image location
            # Spree::Image.change_paths database

            #namespace cache keys
            ENV['RAILS_CACHE_ID']= database
          rescue Exception => e
            Rails.logger.error "  Stopped request due to: #{e.message}"

            #fallback
            ENV['RAILS_CACHE_ID'] = ""
            Apartment::Tenant.switch nil
            ActiveRecord::Base.establish_connection
            return ahh_no
          end

          #continue on to rails
          @app.call(env)
        else
          ahh_no
        end
      end

      def subdomain(request)
        request.subdomain.to_s.split('.').first
      end

      def ahh_no
        [200, {"Content-type" => "text/html"}, ["Ahh No."]]
      end

    end
  end
end