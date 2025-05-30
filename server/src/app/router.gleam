import app/web
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/result
import lustre/attribute
import lustre/element
import lustre/element/html
import pog
import shared
import wisp.{type Request, type Response}

pub fn handle_request(
  req: Request,
  db: pog.Connection,
  static_dir: String,
) -> Response {
  use req <- web.middleware(req, static_dir)
  case wisp.path_segments(req) {
    ["api", "login"] -> login(req, db)
    _ -> index()
  }
}

fn index() -> Response {
  let html =
    html.html([], [
      html.head([], [
        html.meta([attribute.charset("UTF-8")]),
        html.title([], "Excuse my webdev skills 😭"),
        html.script(
          [attribute.type_("module"), attribute.src("/static/client.min.mjs")],
          "",
        ),
      ]),
      html.body([], [html.div([attribute.id("app")], [])]),
    ])

  html
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}

fn login(req: Request, db: pog.Connection) -> Response {
  use <- wisp.require_method(req, http.Post)
  use json <- wisp.require_json(req)

  let object_decoder = {
    use passphrase <- decode.field(0, decode.string)
    decode.success(#(passphrase))
  }

  let result = {
    use body <- result.try(
      decode.run(json, shared.request_data_decoder())
      |> result.replace_error(Nil),
    )

    let query =
      "select passphrase from admins where username = '"
      <> body.username
      <> "' and password = '"
      <> body.password
      <> "'"

    use object <- result.try(
      query
      |> pog.query
      |> pog.returning(object_decoder)
      |> pog.execute(db)
      |> result.replace_error(Nil),
    )

    case object {
      pog.Returned(_, [object]) ->
        Ok(
          shared.ResponseData(object.0)
          |> shared.encode_response_data
          |> json.to_string_tree,
        )
      _ -> Error(Nil)
    }
  }

  case result {
    Ok(json) -> wisp.json_response(json, 201)
    Error(_) -> wisp.unprocessable_entity()
  }
}
