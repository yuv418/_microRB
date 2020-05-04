require 'http'
require 'openssl'
require 'colorize'
require 'json'

class JeepAPI
#  private_class_method :req

  def initialize(base_url:, user_id:, key:, bot: false, verify_ssl: true)
    @user_id = user_id
    @key = key
    @bot = bot
    @base_url = base_url
    @prefix = "/api/v1"
    @authorized = false

    @verify_context = OpenSSL::SSL::SSLContext.new
    if not @verify_ssl
      @verify_context.verify_mode = OpenSSL::SSL::VERIFY_NONE # Unfortunate 
    end

    reqUrl = @bot ? "/checkAuthBot" : "/checkAuth"
    authResp = req method: :post, url: reqUrl, authorization_required: false

    if authResp['msg'] == "ID AUTHENTICATON FALED"
      puts "AUTHORIZATION FAILED".colorize :red
      return
    elsif authResp['msg'] == "ID AUTHORIZED" # Don't just authorize people from errors and stuff
      puts "JEEP BOT API AUTHORIZED".colorize :green
      @authorized = true
    end


  end

  def balance(user:) # TODO override
    req method: :post, url: "/get-bal", params: ({'id'=> user})
  end

  def leaderboard
    req method: :post, url: "/getLB"
  end

  def request(user:, amount:, destination:, message:)
    req method: :post, url: "/sendReq", params: {'to' => user,
                                     'amnt' => amount,
                                     'dest' => destination,
                                     'msg' => message}
  end

  def pay(user:, amount:)
    req method: :post, url: "/pay", params: {
          'from-id' => @user_id,
          'from-key' => @key,
          'to-id' => user,
          'amount' => amount
        }
  end


  def req(method:, url:, params: {}, authorization_required: true) # NOTE method has to be a symbol
    if authorization_required
      if not @authorized
        return false
      end
    end

    resp_str = HTTP.request(
      method,
      @base_url + @prefix + url,
      params: ({
        "auth-id" => @user_id,
        "auth-key" => @key
      }).merge(params),
      ssl_context: @verify_context
    )

    begin
      response = JSON.parse(resp_str.to_s)
    rescue JSON::ParserError
      response = {"msg" => resp_str.to_s}
    end

    response

  end

end

