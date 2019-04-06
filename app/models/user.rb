class User < ApplicationRecord
  has_many:items,dependent: :destroy
  belongs_to:group
end
