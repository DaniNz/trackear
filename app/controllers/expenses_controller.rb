# frozen_string_literal: true

class ExpensesController < ApplicationController
  before_action :authenticate_user!, except: [:accept_invitation]

  before_action :set_expense, only: %i[
    show
    edit
    update
    destroy
  ]

  # GET /expenses
  # GET /expenses.json
  def index
    from = from_param
    to = to_param
    page = params[:page]

    @invitation_id = params.dig(:expense_invitation, :id)
    @invitation = ExpenseInvitation.where(id: @invitation_id, email: current_user.email, status: 'accepted').first || ExpenseInvitation.new
    @expenses_invited_to = ExpenseInvitationService.get_list_from_user(current_user)

    @all_expenses = if @invitation_id.present?
                      Expense.where(user_id: @invitation.user_id).in_period(from, to)
                    else
                      current_user.expenses.in_period(from, to)
                    end
    @expenses = @all_expenses.paginate(page: page, per_page: 10)
    @invitations = current_user.expense_invitations
  end

  # GET /expenses/1
  # GET /expenses/1.json
  def show; end

  # GET /expenses/new
  def new
    @expense = Expense.new
  end

  # GET /expenses/1/edit
  def edit; end

  # POST /expenses
  # POST /expenses.json
  def create
    @expense = current_user.expenses.new(expense_params)

    respond_to do |format|
      if @expense.save
        format.html { redirect_to expenses_url, notice: 'Expense was successfully created.' }
        format.json { render :show, status: :created, location: expenses_url }
      else
        format.html { render :new }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /expenses/1
  # PATCH/PUT /expenses/1.json
  def update
    respond_to do |format|
      if @expense.update(expense_params)
        format.html { redirect_to expenses_url, notice: 'Expense was successfully updated.' }
        format.json { render :show, status: :ok, location: expenses_url }
      else
        format.html { render :edit }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /expenses/1
  # DELETE /expenses/1.json
  def destroy
    @expense.destroy
    respond_to do |format|
      format.html { redirect_to expenses_url, notice: 'Expense was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def download
    expense_id = params[:id]
    receipt = ExpenseReceiptService.download!(current_user, expense_id)
    send_data receipt[:file], filename: receipt[:name], type: receipt[:mime_type]
  rescue StandardError
    redirect_to expenses_url
  end

  def send_invitation
    invitation = current_user.expense_invitations.new(expense_invitation_params)

    respond_to do |format|
      if invitation.save
        format.html { redirect_to expenses_url, notice: 'Invitation sent successfully.' }
        format.json { head :no_content }
      else
        format.html { redirect_to expenses_url, notice: 'There was an error sending your invitation, please try again in a few minutes' }
        format.json { head :no_content }
      end
    end
  end

  def accept_invitation
    @invitation = ExpenseInvitation.find_by(token: params[:token])
    @invitation.accept
    @invitation.save
    User.where(email: @invitation.email).first_or_create(password: Devise.friendly_token[0, 20])
    redirect_to home_url, notice: 'The invitation was accepted, please log in with your Google account'
  end

  def destroy_invitation
    @invitation = current_user.expense_invitations.find(params[:invitation_id])
    @invitation.destroy
    redirect_to expenses_url, notice: 'Invitation successfully removed'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def expense_params
    params.require(:expense).permit(
      :name,
      :price,
      :receipt,
      :from,
      :project_id
    )
  end

  def from_param
    Date.parse(params.fetch(:from))
  rescue StandardError
    Date.today.beginning_of_month
  end

  def to_param
    Date.parse(params.fetch(:to))
  rescue StandardError
    Date.today.end_of_month
  end

  def expense_invitation_params
    params.require(:expense_invitation).permit(
      :name,
      :email
    )
  end
end
