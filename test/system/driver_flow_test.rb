require "application_system_test_case"

class DriverFlowTest < ApplicationSystemTestCase
  def setup
    @driver = users(:driver_no_workshops)
    @operator = users(:one)
    @workshop = workshops(:one)
    @wsc = workshop_service_categories(:tire_express)
  end

  test "full driver flow: add car, request service, operator completes, driver sees history" do
    # Driver signs in and adds a car
    using_session(:driver) do
      sign_in_user(@driver)

      visit new_car_path
      fill_in "car_make", with: "Volkswagen"
      fill_in "car_model", with: "Golf"
      fill_in "car_year", with: "2021"
      fill_in "car_license_plate", with: "ZZ9999AA"
      find("#car_fuel_type").select(I18n.t("cars.fuel_types.gasoline"))
      find('input[type="submit"]').click

      assert_text "Volkswagen"
      assert_text "Golf"

      # Browse workshops
      visit workshops_path
      assert_text @workshop.name

      # Request service from the workshop
      visit new_service_request_path(workshop_id: @workshop.id)
      find("#service_request_car_id").find(:option, text: /Volkswagen Golf/).select_option
      find("#service_request_workshop_service_category_id").find(:option, text: /#{Regexp.escape(@wsc.service_category.name)}/).select_option
      fill_in "service_request_description", with: "Потрібна заміна шин"
      find("#service_request_preferred_time").set(3.days.from_now.change(hour: 10).strftime("%Y-%m-%dT%H:%M"))
      find('input[type="submit"]').click

      assert_text I18n.t("service_requests.create.success")
    end

    # Find the service request created by the driver
    car = Car.find_by!(license_plate: "ZZ9999AA")
    service_request = ServiceRequest.find_by!(car: car, workshop: @workshop)

    # Operator signs in and processes the request
    using_session(:operator) do
      sign_in_user(@operator)

      # Accept the request
      visit workshop_management_workshop_service_request_path(@workshop, service_request)
      click_button I18n.t("workshop_management.service_requests.show.accept")
      assert_text I18n.t("workshop_management.service_requests.accept.success")

      # Start work
      visit workshop_management_workshop_service_request_path(@workshop, service_request)
      click_button I18n.t("workshop_management.service_requests.show.start")
      assert_text I18n.t("workshop_management.service_requests.start.success")

      # Complete work — create service record
      visit new_workshop_management_workshop_service_request_service_record_path(@workshop, service_request)
      fill_in "service_record_summary", with: "Замінено зимову гуму на літню"
      fill_in "service_record_recommendations", with: "Перевірити тиск через 1000 км"
      fill_in "service_record_performed_by", with: "Майстер Іван"
      fill_in "service_record_odometer_at_service", with: "35000"
      fill_in "service_record_labor_cost", with: "400"
      fill_in "service_record_parts_cost", with: "3200"
      find('input[type="submit"]').click
      assert_text I18n.t("workshop_management.service_records.create.success")
    end

    # Driver views car history with the service record
    using_session(:driver) do
      visit car_path(car)
      assert_text "Замінено зимову гуму на літню"
      assert_text "Перевірити тиск через 1000 км"
      assert_text "Майстер Іван"
      assert_text @workshop.name
    end
  end
end
