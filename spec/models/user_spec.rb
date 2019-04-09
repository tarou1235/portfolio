require 'rails_helper'

RSpec.describe User, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
   # 姓、名、メール、パスワードがあれば有効な状態であること
   it "is valid " do
   g=Group.new
   user = g.users.new(
      name: "Aaron",
      )
   expect(user).to be_valid
   end
   # 名がなければ無効な状態であること
   it "is invalid without a first name" do
     g=Group.new
     user = g.users.new(name: nil)
     user.valid?
     expect(user.errors[:name]).to_not include("can't be blank")
   end
   # 姓がなければ無効な状態であること
   it "is invalid without a last name"
   # メールアドレスがなければ無効な状態であること
   it "is invalid without an email address"
   # 重複したメールアドレスなら無効な状態であること
   it "is invalid with a duplicate email address"
   # ユーザーのフルネームを文字列として返すこと
   it "returns a user's full name as a string"
end
