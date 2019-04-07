class User < ApplicationRecord
  has_many:items,dependent: :destroy
  has_many:costs,dependent: :destroy
  belongs_to:group
end
