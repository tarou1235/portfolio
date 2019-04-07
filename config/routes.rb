Rails.application.routes.draw do
  post'/callback',to:'linebot#callback'
  resources:users
  resources:items
end
