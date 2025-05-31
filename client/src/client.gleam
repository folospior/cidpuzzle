import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import shared

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])
  Nil
}

type Model {
  Model(
    username: String,
    password: String,
    returned_text: Option(String),
    error: Option(String),
  )
}

type Msg {
  ServerAuthenticatedUser(Result(Response(String), rsvp.Error))
  UserTypedNewUsername(username: String)
  UserTypedNewPassword(password: String)
  UserSubmittedLoginForm
}

fn init(_) {
  #(Model("", "", None, None), effect.none())
}

fn update(model: Model, msg: Msg) {
  case msg {
    ServerAuthenticatedUser(Ok(response)) -> {
      case response.body |> json.parse(using: shared.response_data_decoder()) {
        Ok(data) -> #(
          Model(..model, returned_text: Some(data.passphrase)),
          effect.none(),
        )
        Error(_) -> #(
          Model(..model, error: Some("The server did an oopsie!!")),
          effect.none(),
        )
      }
    }
    ServerAuthenticatedUser(Error(_)) -> #(
      Model(..model, error: Some("GET OUT!!! I TOLD YOU TO BUZZ OFF DIDNT I")),
      effect.none(),
    )
    UserTypedNewUsername(username) -> #(
      Model(..model, username:, error: None),
      effect.none(),
    )
    UserTypedNewPassword(password) -> #(
      Model(..model, password:, error: None),
      effect.none(),
    )
    UserSubmittedLoginForm -> #(
      Model(..model, error: None, returned_text: None),
      login_request(shared.RequestData(model.username, model.password)),
    )
  }
}

fn login_request(data: shared.RequestData) -> Effect(Msg) {
  let body = shared.encode_request_data(data)
  let url = "/api/login"

  rsvp.post(url, body, rsvp.expect_ok_response(ServerAuthenticatedUser))
}

fn view(model: Model) {
  html.div([], [
    html.h1([], [element.text("Buzz off")]),
    html.div([], [
      html.input([
        event.on_input(UserTypedNewUsername),
        attribute.placeholder("username"),
      ]),
      html.input([
        event.on_input(UserTypedNewPassword),
        attribute.placeholder("password"),
      ]),
      html.button([event.on_click(UserSubmittedLoginForm)], [
        element.text("Login"),
      ]),
    ]),
    html.footer([], [
      html.p([], [
        element.text(
          "real talk - do not leave the bounds of this website, i do NOT want to get my server taken down for getting ddosed lmao",
        ),
      ]),
      element.unsafe_raw_html("", "marquee", [], "signed by sgt.maj. f_o1oo"),
    ]),
    case model.error {
      Some(text) ->
        html.p([attribute.style("color", "red")], [element.text(text)])
      None -> element.none()
    },
    case model.returned_text {
      Some(text) -> html.h2([], [element.text(text)])
      None -> element.none()
    },
  ])
}
