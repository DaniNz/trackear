class User < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :project_contracts
  has_many :projects, through: :project_contracts

  has_many :activity_tracks

  def slug_candidates
    [[:first_name, :last_name, :slug_suffix]]
  end

  def slug_suffix
    SecureRandom.hex(3)
  end

  def create_owner_contract_for(project)
    project_contracts.create(
        activity: "Owner",
        project: project,
        active_from: Date.today,
        ends_at: Date.today.next_year,
        user_rate: 0,
        project_rate: 0
    )
  end

  def currently_active_contract_for(project)
    project_contracts.currently_active.find_by(project: project)
  end

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data['email']).first
    user_is_invited_but_uninitialized = user && !user.picture.present?

    if user_is_invited_but_uninitialized
      user.update(
          first_name: data['first_name'],
          last_name: data['last_name'],
          picture: data['image'],
          password: Devise.friendly_token[0, 20]
      )
    end

    # debug code, remove!
    unless user
      user = User.create(
          email: data['email'],
          first_name: data['first_name'],
          last_name: data['last_name'],
          picture: data['image'],
          password: Devise.friendly_token[0, 20]
      )
    end

    user
  end
end
