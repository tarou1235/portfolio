Rails.application.routes.draw do
  root 'application#hello'
  post'/callback',to:'linebot#callback'
  resources:costs
  resources:items
end
