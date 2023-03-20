class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable

  enum role: { admin: 0, normal: 1 }
  # rest of the code

  def self.role_options
    roles.keys.to_a.map { |role| [role.titleize, role] }
  end

end
