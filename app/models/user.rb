class User < ApplicationRecord
  has_many:items,foreign_key:"line_id",dependent: :destroy
end
