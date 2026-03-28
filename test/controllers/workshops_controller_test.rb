require "test_helper"

class WorkshopsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @workshop = workshops(:one)
    @tire_service = service_categories(:tire_service)
    @car_wash = service_categories(:car_wash)
    sign_in @user
  end

  # --- Form rendering ---

  test "new form renders a checkbox per service category" do
    get new_workshop_path
    assert_response :success
    assert_select "[data-controller='pricing-fields']", count: ServiceCategory.count
    assert_select "input[type=checkbox][data-pricing-fields-target='checkbox']", count: ServiceCategory.count
  end

  test "edit form checks selected categories and shows pricing fields" do
    get edit_workshop_path(@workshop)
    assert_response :success

    # selected category checkbox is checked
    assert_select "input[type=checkbox][data-pricing-fields-target='checkbox'][checked]", minimum: 1

    # pricing fields are present for the selected category
    assert_select "input[name*='workshop_service_categories_attributes'][name*='price_min']", minimum: 1
  end

  # --- Index: only active workshops (Task 31) ---

  test "index excludes pending workshops" do
    sign_out @user
    get workshops_path
    assert_response :success
    assert_select "h2", text: workshops(:pending_workshop).name, count: 0
  end

  test "index excludes declined workshops" do
    sign_out @user
    get workshops_path
    assert_response :success
    assert_select "h2", text: workshops(:declined_workshop).name, count: 0
  end

  test "index excludes suspended workshops" do
    sign_out @user
    get workshops_path
    assert_response :success
    assert_select "h2", text: workshops(:suspended_workshop).name, count: 0
  end

  test "show returns 404 for pending workshop when not owner" do
    sign_in users(:driver_no_workshops)
    get workshop_path(workshops(:pending_workshop))
    assert_response :not_found
  end

  test "show returns 404 for declined workshop when not owner" do
    sign_in users(:driver_no_workshops)
    get workshop_path(workshops(:declined_workshop))
    assert_response :not_found
  end

  test "show returns 404 for suspended workshop when not owner" do
    sign_in users(:driver_no_workshops)
    get workshop_path(workshops(:suspended_workshop))
    assert_response :not_found
  end

  test "show returns 404 for pending workshop when not signed in" do
    sign_out @user
    get workshop_path(workshops(:pending_workshop))
    assert_response :not_found
  end

  test "show renders active workshop" do
    get workshop_path(@workshop)
    assert_response :success
    assert_select "h1", text: @workshop.name
  end

  test "show allows owner to view their pending workshop" do
    sign_in users(:three)
    get workshop_path(workshops(:pending_workshop))
    assert_response :success
  end

  # --- Authorization on edit/update/destroy ---

  test "edit requires workshop access" do
    sign_in users(:driver_no_workshops)
    get edit_workshop_path(@workshop)
    assert_redirected_to root_path
  end

  test "update requires workshop access" do
    sign_in users(:driver_no_workshops)
    patch workshop_path(@workshop), params: { workshop: { name: "Hack" } }
    assert_redirected_to root_path
  end

  test "destroy requires workshop access" do
    sign_in users(:driver_no_workshops)
    delete workshop_path(@workshop)
    assert_redirected_to root_path
  end

  # --- Index with near filter (Task 29) ---

  test "index without near param returns all active workshops" do
    get workshops_path
    assert_response :success
  end

  test "index with near param filters by proximity" do
    get workshops_path, params: { near: "50.45,30.52" }
    assert_response :success
  end

  test "index with invalid near param returns all active workshops" do
    get workshops_path, params: { near: "invalid" }
    assert_response :success
  end

  # --- Create (Task 30) ---

  test "create sets workshop status to pending" do
    post workshops_path, params: {
      workshop: {
        name: "Нова майстерня",
        phone: "+380501111111",
        address: "вул. Тестова, 1",
        city: "Київ",
        country: "UA"
      }
    }

    created = Workshop.order(:created_at).last
    assert created.pending?
  end

  test "create assigns current user as owner via workshop_operators" do
    assert_difference "WorkshopOperator.count", 1 do
      post workshops_path, params: {
        workshop: {
          name: "Нова майстерня",
          phone: "+380501111111",
          address: "вул. Тестова, 1",
          city: "Київ",
          country: "UA"
        }
      }
    end

    created = Workshop.order(:created_at).last
    operator = created.workshop_operators.find_by(user: @user)
    assert_not_nil operator
    assert operator.owner?
  end

  test "create redirects with submitted flash message" do
    post workshops_path, params: {
      workshop: {
        name: "Нова майстерня",
        phone: "+380501111111",
        address: "вул. Тестова, 1",
        city: "Київ",
        country: "UA"
      }
    }

    created = Workshop.order(:created_at).last
    assert_redirected_to workshop_path(created)
    follow_redirect!
    assert_match I18n.t("workshops.create.submitted"), flash[:notice]
  end

  test "create with invalid data does not create workshop_operator" do
    assert_no_difference "WorkshopOperator.count" do
      post workshops_path, params: {
        workshop: { name: "", phone: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create with pricing data saves workshop_service_categories" do
    assert_difference "WorkshopServiceCategory.count", 1 do
      post workshops_path, params: {
        workshop: {
          name: "Тестова майстерня",
          phone: "+380501111111",
          address: "вул. Тестова, 1",
          city: "Київ",
          country: "UA",
          workshop_service_categories_attributes: {
            "0" => {
              service_category_id: @tire_service.id,
              _destroy: "0",
              price_min: "100",
              price_max: "500",
              price_unit: "послуга",
              estimated_duration_minutes: "30"
            },
            "1" => {
              service_category_id: @car_wash.id,
              _destroy: "1"
            }
          }
        }
      }
    end

    created = Workshop.order(:created_at).last
    assert_redirected_to workshop_path(created)

    wsc = created.workshop_service_categories.find_by(service_category: @tire_service)
    assert_not_nil wsc
    assert_equal 100, wsc.price_min.to_i
    assert_equal 500, wsc.price_max.to_i
    assert_equal "послуга", wsc.price_unit
    assert_equal 30, wsc.estimated_duration_minutes

    assert_nil created.workshop_service_categories.find_by(service_category: @car_wash)
  end

  test "create with all categories deselected creates no WSC records" do
    assert_difference "WorkshopServiceCategory.count", 0 do
      post workshops_path, params: {
        workshop: {
          name: "Порожня майстерня",
          phone: "+380501111111",
          address: "вул. Тестова, 2",
          city: "Київ",
          country: "UA",
          workshop_service_categories_attributes: {
            "0" => { service_category_id: @tire_service.id, _destroy: "1" },
            "1" => { service_category_id: @car_wash.id, _destroy: "1" }
          }
        }
      }
    end

    created = Workshop.order(:created_at).last
    assert_empty created.workshop_service_categories
  end

  # --- Update ---

  test "update adds new category with pricing" do
    assert_not_includes @workshop.service_category_ids, @car_wash.id

    existing_wsc = workshop_service_categories(:tire_express)

    patch workshop_path(@workshop), params: {
      workshop: {
        workshop_service_categories_attributes: {
          "0" => {
            id: existing_wsc.id,
            service_category_id: @tire_service.id,
            _destroy: "0",
            price_min: existing_wsc.price_min,
            price_max: existing_wsc.price_max,
            price_unit: existing_wsc.price_unit,
            estimated_duration_minutes: existing_wsc.estimated_duration_minutes
          },
          "1" => {
            service_category_id: @car_wash.id,
            _destroy: "0",
            price_min: "200",
            price_max: "800",
            price_unit: "авто",
            estimated_duration_minutes: "60"
          }
        }
      }
    }

    assert_redirected_to workshop_path(@workshop)
    @workshop.reload
    assert_includes @workshop.service_category_ids, @tire_service.id
    assert_includes @workshop.service_category_ids, @car_wash.id

    new_wsc = @workshop.workshop_service_categories.find_by(service_category: @car_wash)
    assert_equal 200, new_wsc.price_min.to_i
    assert_equal 800, new_wsc.price_max.to_i
    assert_equal "авто", new_wsc.price_unit
    assert_equal 60, new_wsc.estimated_duration_minutes
  end

  test "update removes deselected category" do
    existing_wsc = workshop_service_categories(:tire_express)
    assert_includes @workshop.service_category_ids, @tire_service.id

    assert_difference "WorkshopServiceCategory.count", -1 do
      patch workshop_path(@workshop), params: {
        workshop: {
          workshop_service_categories_attributes: {
            "0" => {
              id: existing_wsc.id,
              service_category_id: @tire_service.id,
              _destroy: "1"
            }
          }
        }
      }
    end

    @workshop.reload
    assert_empty @workshop.service_categories
  end

  test "update modifies pricing on existing category" do
    existing_wsc = workshop_service_categories(:tire_express)

    patch workshop_path(@workshop), params: {
      workshop: {
        workshop_service_categories_attributes: {
          "0" => {
            id: existing_wsc.id,
            service_category_id: @tire_service.id,
            _destroy: "0",
            price_min: "999",
            price_max: "2000",
            price_unit: "колесо",
            estimated_duration_minutes: "15"
          }
        }
      }
    }

    assert_redirected_to workshop_path(@workshop)
    existing_wsc.reload
    assert_equal 999, existing_wsc.price_min.to_i
    assert_equal 2000, existing_wsc.price_max.to_i
    assert_equal "колесо", existing_wsc.price_unit
    assert_equal 15, existing_wsc.estimated_duration_minutes
  end
end
