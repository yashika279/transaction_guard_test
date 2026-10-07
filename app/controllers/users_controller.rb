# frozen_string_literal: true

class UsersController < ApplicationController
  # JSON create endpoint for local curl testing — skip browser CSRF.
  skip_forgery_protection

  # Creating a user runs User#after_create (job + email) inside the save transaction.
  def create
    user = User.create!(name: params.require(:name))
    render json: { id: user.id, name: user.name }, status: :created
  rescue TransactionGuard::Error => error
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
