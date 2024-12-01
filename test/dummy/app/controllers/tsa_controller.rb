# frozen_string_literal: true

class TsaController < ApplicationController
  # @route GET /tsa (tsa_index)
  def index
    render json: { data: Passenger.all.map(&method(:passenger_summary)) }
  end

  # @route GET /tsa/:id (tsa)
  def show
    render_passenger_data
  end

  # @route POST /tsa/:id/add (add_tsa)
  def set
    find_passenger.update(passenger_params(:set_special_needs,
                                           set_meal_preferences: []))
    render_passenger_data
  end

  # @route POST /tsa/:id/append (append_tsa)
  def append
    find_passenger.update(passenger_params(:add_special_needs, :add_meal_preferences))
    render_passenger_data
  end

  # @route DELETE /tsa/:id/remove (remove_tsa)
  def remove
    find_passenger.update(passenger_params(:remove_special_needs, :remove_meal_preferences))
    render_passenger_data
  end

  # @route DELETE /tsa/:id (tsa)
  def destroy
    find_passenger.clear_special_needs!
    find_passenger.clear_meal_preferences!
    render_passenger_data
  end

  private

  def render_passenger_data
    render json: { data: find_passenger.to_h }
  end

  def passenger_summary(passenger)
    {
      id: passenger.id,
      name: passenger.full_name
    }
  end

  def find_passenger
    Passenger.find(params[:id])
  end

  def passenger_params(*attributes)
    params.require(:passenger).permit(*attributes)
  end
end
