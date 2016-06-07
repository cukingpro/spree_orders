Spree::Shipment.class_eval do
  scope :time_frame, ->(time_frame_id) { where(time_frame_id: time_frame_id) }
  scope :deliverer, ->(user_id) { where(user_id: user_id) }
  scope :date, ->(date) { where(date_delivery: date) }
  scope :available, -> { where(state: "ready", user_id: nil)}

  belongs_to :deliverer, :class_name => "Spree::User", :foreign_key => "user_id"

    accepts_nested_attributes_for :deliverer,
    :reject_if => :all_blank,
    :allow_destroy => true


  def self.available_shipments
    Spree::Shipment.where(state: "ready", user_id: nil)
  end

  def self.user_history_shipments(user)
    Spree::Shipment.where(user_id: user.id, state: "shipped")
  end

  def self.user_next_shipments(user)
    Spree::Shipment.where(user_id: user.id, state: "ready")
  end

  def self.optimize(shipments)
    addresses = shipments.map{ |shipment|
      shipment.address.to_string
    }
    gmaps = GoogleMapsService::Client.new
    routes = gmaps.directions(
      COMPANY_ADDRESS, 
      COMPANY_ADDRESS,
      waypoints: addresses ,
      optimize_waypoints: true,
      mode: 'driving',
        region: 'vn',
        alternatives: false)

    waypoint_order = routes.first[:waypoint_order]

    return shipments.values_at *waypoint_order
  end

  def self.assign(shipments, deliverers)
    optimize_shipments = Spree::Shipment.optimize(shipments)
    number_of_deliverer = deliverers.count
    split_shipments = optimize_shipments.in_groups(number_of_deliverer, false)
    deliverers.each_with_index { |d,i| 
      d.shipments << split_shipments[i] if split_shipments[i]!=[]
    } 

  end
  
  def self.everyday_assign
    deliverers = Spree::User.deliverers
    Dish::TimeFrame.all.each do |time|
      shipments = Spree::Shipment.date(Date.today).time_frame(time.id).available
      Spree::Shipment.assign(shipments, deliverers) unless shipments == []
    end
  end

end
