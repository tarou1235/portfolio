class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

 @@name=nil
 @@payment=nil
 @@image=nil
 @@destroy=nil

  def client
        @@client ||= Line::Bot::Client.new { |config|
          config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
            config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
        }
  end

  def callback
          body = request.body.read
          signature = request.env['HTTP_X_LINE_SIGNATURE']
          unless client.validate_signature(body, signature)
            head :bad_request
          end
          events = client.parse_events_from(body)

      events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.message['text']
        when "立替" then
            @@name=nil
            @@payment=nil
            @@destroy=nil
            message = {
              type: 'text',
              text: '立て替えた内容を教えていただけますか'
            }
            client.push_message(event['source']['userId'], message)
            @@name="仮"
        when "編集" then
          message = {
            type: 'text',
            text: 'どの立替分を編集しますか？'
          }
          client.push_message(event['source']['userId'], message)
          user=User.find_by(line_id:event['source']['userId'])#user_id:event['source']['userId']
          costs=user.costs
          columns=[]
          costs.first(10).each do |cost|
          columns.push(
              {
                "thumbnailImageUrl": "https://example.com/bot/images/item1.jpg",
                "imageBackgroundColor": "#FFFFFF",
                "title": cost.name,
                "text":  cost.payment.to_s(:currency),
                "actions": [
                    {
                        "type": "uri",
                        "label": "編集",
                        "uri": "https://tagu2.herokuapp.com/costs/#{cost.id}/edit"
                    },
                    {
                        "type": "postback",
                        "label": "削除",
                        "data": "destroy,#{cost.id}"
                    },
                    {
                      "type": "postback",
                      "label": "何もしない",
                      "data": "nothing"
                    }
                ]
              }
        )
                       end
          message1=  {
                  "type": "template",
                  "altText": "this is a carousel template",
                  "template": {
                                "type": "carousel",
                                "columns": columns,
                                "imageAspectRatio": "rectangle",
                                "imageSize": "cover"
                              }
           }
          client.push_message(event['source']['userId'], message1)

        when "支払い" then
            user=User.find_by(line_id:event['source']['userId'])#user_id:event['source']['userId']
          columns=[]
          if user.items then
          items=user.items
            items_sum=0

            items.each do |item|
            karipayment=item.payment
            items_sum=items_sum+karipayment
            columns.push(
                    {
                      "type": "box",
                      "layout": "horizontal",
                      "contents":
                      [
                        {
                          "type": "text",
                          "text": item.cost.name.to_s,
                          "size": "sm",
                          "color":  "#555555",
                          "flex": 0
                        },
                        {
                          "type": "text",
                          "text": karipayment.to_s(:currency),
                          "size": "sm",
                          "color":   "#111111",
                          "align": "end"
                        }
                      ]
                    }
                          )
            end
          end
          if user.costs then
            costs=user.costs
            costs_sum=0
            costs.each do |cost|
            karipayment=-cost.payment
            costs_sum=costs_sum+karipayment
            columns.push(
                    {
                      "type": "box",
                      "layout": "horizontal",
                      "contents":
                      [
                        {
                          "type": "text",
                          "text": cost.name.to_s + "(立替分)",
                          "size": "sm",
                          "color":  "#555555",
                          "flex": 0
                        },
                        {
                          "type": "text",
                          "text": karipayment.to_s(:currency),
                          "size": "sm",
                          "color":"#f90909",
                          "align": "end"
                        }
                      ]
                    }
                          )
                        end
          end
          bubble ={
                      "type": "bubble",
                      "styles": {
                                  "footer": {
                                              "separator": true
                                            }
                                 },
                        "body": {
                                "type": "box",
                                "layout": "vertical",
                                "contents":
                                [
                                  {
                                    "type": "text",
                                    "text": "#{user.name}さん",
                                    "weight": "bold",
                                    "color": "#1DB446",
                                    "size": "sm"
                                  },
                                  {
                                    "type": "text",
                                    "text": "支払い予定額",
                                    "weight": "bold",
                                    "size": "xxl",
                                    "margin": "md"
                                  },
                                  {
                                    "type": "text",
                                    "text": "※現時点の金額となります",
                                    "size": "xs",
                                    "color": "#aaaaaa",
                                    "wrap": true
                                  },
                                  {
                                    "type": "separator",
                                    "margin": "xxl"
                                  },
                                  {
                                    "type": "box",
                                    "layout": "vertical",
                                    "margin": "xxl",
                                    "spacing": "sm",
                                    "contents": columns
                                  },
                                  {
                                       "type": "separator",
                                       "margin": "xxl"
                                     },
                                  {
                                       "type": "box",
                                       "layout": "horizontal",
                                       "margin": "xxl",
                                       "contents": [
                                         {
                                           "type": "text",
                                           "text": "合計",
                                           "size": "md",
                                           "weight": "bold",
                                           "color":  "#555555"
                                         },
                                         {
                                           "type": "text",
                                           "text": (costs_sum+items_sum).to_s(:currency),
                                           "size": "md",
                                           "weight": "bold",
                                           "color":  "#111111",
                                           "align": "end"
                                         }
                                                    ]
                                  },
                                  {
                                                        "type": "text",
                                                        "text": "※マイナスの場合はお金をもらってください",
                                                        "size": "xs",
                                                        "color": "#aaaaaa",
                                                        "wrap": true
                                                      }
                                 ]
                               }
                  }
          message1={
                                    "type": "flex",
                                    "altText": "this is a flex message",
                                    "contents":bubble
                  }
          client.push_message(event['source']['userId'], message)
          client.push_message(event['source']['userId'], message1)

        when "開始" then
          message = {
            type: 'text',
            text: 'この度、会計係を務めさせていただくタグチと申します。よろしくお願いします。'
          }
          message1 ={
                              "type": "template",
                              "altText": "参加確認",
                              "template": {
                                  "type": "confirm",
                                  "text": "今回の企画に参加される方は、まずはこちらの参加ボタンを押してください",
                                  "actions": [
                                      {
                                        "type": "postback",
                                        "data":"join",
                                        "label": "参加",
                                        "displayText": "参加"
                                      },
                                      {
                                        "type": "postback",
                                        "data":"unjoin",
                                        "label": "参加しない",
                                        "displayText": "参加しない"
                                      }
                                  ]
                              }
             }
             message2 = {
               type: 'text',
               text: line_name(event['source']['groupId'])
             }
          Group.create(line_group_id:event['source']['groupId']) if !Group.find_by(line_group_id:event['source']['groupId'])
          client.push_message(event['source']['groupId'], message)
          client.push_message(event['source']['groupId'], message1)
          client.push_message(event['source']['groupId'], message2)
        when "確認" then
            @@contents=[]
              group=Group.find_by(line_group_id:event['source']['groupId'])
              users=group.users.all
              users.each do |user|
              make_contents(user,"確認") if user
              end
             bubbles = {
                        "type": "carousel",
                        "contents": @@contents
                      }
            message =
                      {
                                        "type": "flex",
                                        "altText": "this is a flex message",
                                        "contents":bubbles
                      }
            client.push_message(event['source']['groupId'], message)
        when "終了" then
              @@contents=[]
              @@items_data=[]
              group=Group.find_by(line_group_id:event['source']['groupId'])
              users=group.users.all
              users.each do |user|
                make_items(user,"終了")
              end
                make_contents("仮","終了")
                bubble ={
                            "type": "bubble",
                            "styles": {
                                        "footer": {
                                                    "separator": true
                                                  }
                                       },
                              "body": {
                                      "type": "box",
                                      "layout": "vertical",
                                      "contents":@@contents
                                     }
                        }
                message={
                                          "type": "flex",
                                          "altText": "this is a flex message",
                                          "contents":bubble
                        }
              client.push_message(event['source']['groupId'], message)
        else
          if @@name&&@@payment&&@@image then
              @@image=SecureRandom.uuid
              image_response = client.get_message_content(event.message['id'])
              File.binwrite("public/cost_images/#{@@image}", image_response.body)
              user=User.find_by(line_id:event['source']['userId'])
              cost=Cost.create(name:@@name,payment:@@payment,user_id:user.id,image_name: @@image)
              warikan(cost)
              message = {
                type: 'text',
                text: 'それでは登録いたします'
              }
              client.push_message(event['source']['userId'], message)
              @@payment=nil
              @@name=nil
              @@image=nil
          end

            if @@name&&@@payment&&!@@image then

                @@payment=event.message['text'].tr('０-９ａ-ｚＡ-Ｚ','0-9a-zA-Z').gsub(/[^\d]/, "").to_i #半角にして、数字のみ抽出
                @@image="仮"
                #user=User.find_by(line_id:event['source']['userId'])
                #cost=Cost.create(name:@@name,payment:@@payment,user_id:user.id)
                #warikan(cost)
                #message = {
                  #type: 'text',
                  #text: 'それでは登録いたします'
                #}
                #client.push_message(event['source']['userId'], message)
                #@@payment=nil
                #@@name=nil
            end

            if @@name&&!@@payment&&!@@image then
              @@name=event.message['text']
                message = {
                  type: 'text',
                  text: '続いて、支払い金額を教えていただけますか'
                }
              client.push_message(event['source']['userId'], message)
              @@payment=0
            end

            if @@destroy then
                if event.message['text'] == "はい" then
                  message = {
                    type: 'text',
                    text: '削除いたしました'
                  }
                  client.push_message(event['source']['userId'], message)
                @@destroy.destroy
                else
                  message = {
                    type: 'text',
                    text: '承知いたしました'
                  }
                  client.push_message(event['source']['userId'], message)
                end
            end
        end
      when Line::Bot::Event::Postback
        events.each {|event|
                          postback=event['postback']['data'].split(",")
                          case postback[0]
                          when "join"
                              message = {
                                type: 'text',
                                text: "ご参加ありがとうございます。立て替え払いをされた場合は、下のメニューにてお知らせください"
                              }
                              group=Group.find_by(line_group_id:event['source']['groupId'])
                              if line_name(event['source']['userId'])
                                if !group.users.find_by(line_id: event['source']['userId'])
                                  group.users.create(name:line_name(event['source']['userId']),line_id: event['source']['userId'])
                                  client.push_message(event['source']['userId'], message)
                                end
                              else
                                message = {
                                  type: 'text',
                                  text: "友達登録がまだの方は、まずは友達登録をお願いします"
                                }
                                client.push_message(event['source']['groupId'], message)
                              end

                            when "edit"
                                message = {
                                  type: 'text',
                                  text: "ご参加ありがとうございます。立て替え払いをされた場合は、下のメニューにてお知らせください"
                                }
                                line_id=event['source']['userId']
                                User.create(name:line_name(line_id),line_id:event['source']['userId'])
                                client.push_message(event['source']['userId'], message)

                            when "destroy"
                                  message = {
                                              "type": "template",
                                              "altText": "this is a confirm template",
                                              "template": {
                                                  "type": "confirm",
                                                  "text": "本当に削除してもよろしいでしょうか？",
                                                  "actions": [
                                                      {
                                                        "type": "message",
                                                        "label": "Yes",
                                                        "text": "はい"
                                                      },
                                                      {
                                                        "type": "message",
                                                        "label": "No",
                                                        "text": "いいえ"
                                                      }
                                                  ]
                                              }
                                            }
                                  client.push_message(event['source']['userId'], message)
                                  @@destroy=Cost.find(postback[1].to_i)
                            when "nothing"
                                      message = {
                                        type: 'text',
                                        text: "承知いたしました"
                                      }
                                      client.push_message(event['source']['userId'], message)
                          end
                }
      end
    }
    head :ok



  end

  def line_name(line_id)
   response = @@client.get_profile(line_id)
   case response
   when Net::HTTPSuccess then
     return JSON.parse(response.body)['displayName']
   end
  end

  def warikan(cost)
   group=cost.user.group
   users=group.users.all
   per_payment=cost.payment/users.count
   sabun=cost.payment-per_payment*users.count
   users.each{|user|
                if user==users.first then
                  Item.create(payment:per_payment+sabun,cost_id:cost.id,user_id:user.id)
                else
                  Item.create(payment:per_payment,cost_id:cost.id,user_id:user.id)
                end
             }
  end

  def make_contents(user,type)
        case type
          when "確認" then
          if user.costs
            costs=user.costs
            costs.each do |cost|
              make_items(cost,"確認")
                 @@contents.push({
                            "type": "bubble",
                            "styles": {
                                        "footer": {
                                                    "separator": true
                                                  }
                                       },
                             "body": {
                                      "type": "box",
                                      "layout": "vertical",
                                      "contents":
                                      [
                                            {
                                              "type": "text",
                                              "text": cost.name,
                                              "weight": "bold",
                                              "size": "xxl",
                                              "margin": "md"
                                            },
                                        {
                                          "type": "text",
                                          "text": "支払い者  #{user.name}さん",
                                          "weight": "bold",
                                          "color": "#1DB446",
                                          "size": "sm"
                                        },
                                        {
                                          "type": "separator",
                                          "margin": "xxl"
                                        },
                                        {
                                          "type": "box",
                                          "layout": "vertical",
                                          "margin": "xxl",
                                          "spacing": "sm",
                                          "contents": @@items_data
                                        },
                                        {
                                          "type": "separator",
                                          "margin": "xxl"
                                        },
                                        {
                                             "type": "box",
                                             "layout": "horizontal",
                                             "margin": "xxl",
                                             "contents": [
                                               {
                                                 "type": "text",
                                                 "text": "合計",
                                                 "size": "md",
                                                 "weight": "bold",
                                                 "color":  "#555555"
                                               },
                                               {
                                                 "type": "text",
                                                 "text": cost.payment.to_s(:currency),
                                                 "size": "md",
                                                 "weight": "bold",
                                                 "color":  "#111111",
                                                 "align": "end"
                                               }
                                                          ]
                                        }



                                       ]
                                     }
                                  })
            end
          end
          when "終了" then
          @@contents.push(
            {
              "type": "text",
              "text": "最終精算額",
              "weight": "bold",
              "size": "xxl",
              "margin": "md"
            },
            {
              "type": "separator",
              "margin": "xxl"
            },
            {
              "type": "box",
              "layout": "vertical",
              "margin": "xxl",
              "spacing": "sm",
              "contents": @@items_data
            },
            {
                 "type": "separator",
                 "margin": "xxl"
            },
            {
                                  "type": "text",
                                  "text": "※マイナスの場合はお金をもらってください",
                                  "size": "xs",
                                  "color": "#aaaaaa",
                                  "wrap": true
            }
           )
        end
 end

  def make_items(obj,type)
    case type
    when "確認" then
      @@items_data=[]
      if obj.items
          items=obj.items
          items.each do |item|
          @@items_data.push(
                  {
                    "type": "box",
                    "layout": "horizontal",
                    "contents":
                    [
                      {
                        "type": "text",
                        "text": item.user.name.to_s + "さん",
                        "size": "sm",
                        "color":  "#555555",
                        "flex": 0
                      },
                      {
                        "type": "text",
                        "text": item.payment.to_s(:currency),
                        "size": "sm",
                        "color":"#555555",
                        "align": "end"
                      }
                    ]
                  }) end

      end
    when "終了" then
      sum=0
        if obj.costs
          costs=obj.costs
          costs.each do |cost|
            sum -= cost.payment
          end
        end

        if obj.items
          items=obj.items
          items.each do |item|
            sum += item.payment
          end
        end
       @@items_data.push(
                        {
                          "type": "box",
                          "layout": "horizontal",
                          "contents":
                          [
                            {
                              "type": "text",
                              "text": obj.name.to_s + "さん",
                              "size": "sm",
                              "color":  "#555555",
                              "flex": 0
                            },
                            {
                              "type": "text",
                              "text": sum.to_s(:currency),
                              "size": "sm",
                              "color":"#555555",
                              "align": "end"
                            }
                          ]
                        }
                       )
    end
  end



end
