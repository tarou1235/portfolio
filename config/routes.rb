Rails.application.routes.draw do
  root 'application#hello'  
  post'/callback',to:'linebot#callback'
  resources:users
  resources:items
end
