class Item < ApplicationRecord
  belongs_to:line,class_name:"User"
end
