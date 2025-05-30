import gleam/dynamic/decode
import gleam/json

pub type RequestData {
  RequestData(username: String, password: String)
}

pub fn encode_request_data(data: RequestData) -> json.Json {
  let RequestData(username:, password:) = data
  json.object([
    #("username", json.string(username)),
    #("password", json.string(password)),
  ])
}

pub fn request_data_decoder() -> decode.Decoder(RequestData) {
  use username <- decode.field("username", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(RequestData(username:, password:))
}

pub type ResponseData {
  ResponseData(passphrase: String)
}

pub fn encode_response_data(response_data: ResponseData) -> json.Json {
  let ResponseData(passphrase:) = response_data
  json.object([#("passphrase", json.string(passphrase))])
}

pub fn response_data_decoder() -> decode.Decoder(ResponseData) {
  use passphrase <- decode.field("passphrase", decode.string)
  decode.success(ResponseData(passphrase:))
}
