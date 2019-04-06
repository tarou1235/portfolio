class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

 @@naiyou_flag=false
 @@name=nil
 @@payment=nil
 @@destroy=nil

  def client
        @client ||= Line::Bot::Client.new { |config|
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
          @@items=user.items(paytype:"host")
          @@columns=[]
          @@items.first(10).each do |item|
          @@columns.push(
              {
                "thumbnailImageUrl": "https://example.com/bot/images/item1.jpg",
                "imageBackgroundColor": "#FFFFFF",
                "title": item.name,
                "text":  item.payment,
                "actions": [
                    {
                        "type": "uri",
                        "label": "編集",
                        "uri": "http://example.com/page/111"
                    },
                    {
                        "type": "postback",
                        "label": "削除",
                        "data": "destroy,#{item.id}"
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



          message1=
          {
                  "type": "template",
                  "altText": "this is a carousel template",
                  "template": {
                                "type": "carousel",
                                "columns": @@columns,
                                "imageAspectRatio": "rectangle",
                                "imageSize": "cover"
                              }
           }
          client.push_message(event['source']['userId'], message1)



        when "開始" then
          message = {
            type: 'text',
            text: 'この度、会計係を務めさせていただくタグチと申します。よろしくお願いします。'
          }
          message1 =
            {
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
          client.push_message(event['source']['groupId'], message)
          client.push_message(event['source']['groupId'], message1)

        else
            if @@name&&@@payment then
                @@payment=event.message['text'].to_i
                user=User.find_by(line_id:event['source']['userId'])
                user.items.create(payment:@@payment,name:@@name,paytype:"host")
                warikan(@@payment,@@name)
                message = {
                  type: 'text',
                  text: 'それでは登録いたします'
                }
                client.push_message(event['source']['userId'], message)
                @@payment=nil
                @@name=nil
            end

            if @@name&&!@@payment then
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

                              @@line_id=event['source']['userId']
                              User.create(name:line_name(@@line_id),line_id: @@line_id)
                              client.push_message(event['source']['userId'], message)

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
                                  @@destroy=Item.find(postback[1].to_i)
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
   response = @client.get_profile(line_id)
   case response
   when Net::HTTPSuccess then
     return JSON.parse(response.body)['displayName']
   end
 end

 def warikan(payment,name)
   payment=-1*payment/User.count
   users=User.all
   users.each{|user|
     user.items.create(payment:payment,name:name,paytype:"payer")
   }
 end



end
