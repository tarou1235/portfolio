class Group < ApplicationRecord
  has_many:users,dependent: :destroy
end
