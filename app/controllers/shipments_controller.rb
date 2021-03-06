require 'active_shipping'
require 'timeout'

class ShipmentsController < ApplicationController
  before_action :origin, :destination, :packages

  def get_rates_from_shipper(shipper)
    response = shipper.find_rates(origin, destination, packages)
    response.rates.sort_by(&:price) #might be total_price
  end

  def ups_rates
    ups = ActiveShipping::UPS.new(login: ENV['UPS_LOGIN'], password: ENV['UPS_PW'], key: ENV['UPS_KEY'])
    get_rates_from_shipper(ups)
  end

  # def fedex_rates
  #   fedex = ActiveShipping::FedEx.new(login: ENV['FEDEX_METER_NO'], password: ENV['FEDEX_PW'], account: ENV['FEDEX_ACCT'], test: true)
  #   get_rates_from_shipper(fedex)
  # end

  def usps_rates
    usps = ActiveShipping::USPS.new(login: ENV['USPS_LOGIN'])
    get_rates_from_shipper(usps)
  end

  def create
    begin
      Timeout::timeout(10) {
        logger.info("Request for shipment of box size 10x10x10 from facility at Seattle, WA 98161. Weight ofpackage  and final destination: #{ params }")
        shipment = Shipment.new(shipment_params)
        shipment.save
        logger.info("Response returned: ups => #{ ups_rates }, usps => #{ usps_rates }")

        return render json: { "ups" => ups_rates, "usps" => usps_rates }, status: :created
      }

    rescue ActiveShipping::ResponseError
      render json: { error: "Looks like some information isn't correct. Please try again."}

    rescue Timeout::Error
      return render json: { error: "This is taking too long. Try refreshing your page." }
    end

  end

  private

  def shipment_params
    params.permit([params[:shipment], params[:weight], params[:country], params[:state], params[:city], params[:zip]])
  end

  def origin
    ActiveShipping::Location.new(country: "US", state: "WA", city: "Seattle", zip: "98161")
  end

  def destination
    # ActiveShipping::Location.new(country: "US", state: "RI", city: "Providence", zip: "02905")
    ActiveShipping::Location.new(country: params[:country], state: params[:state], city: params[:city], zip: params[:zip])
  end

  def packages
    ActiveShipping::Package.new(params[:weight].to_i, [10, 10, 10])
  end

end
