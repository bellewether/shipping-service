class Package < ActiveRecord::Base
  belongs_to :shipment

  validates :weight, :length, :width, :height, presence: true

  attr_reader :weight, :length, :width, :height

  def initialize (weight, length, width, height)
    @weight = weight
    @length = length
    @width = width
    @height = height
  end

end
