import app/router
import envoy
import gleam/erlang/process
import gleam/option.{Some}
import mist
import pog
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()

  let secret = wisp.random_string(64)

  let assert Ok(host) = envoy.get("POSTGRES_HOST")
  let assert Ok(database) = envoy.get("POSTGRES_DB")
  let assert Ok(username) = envoy.get("POSTGRES_USER")
  let assert Ok(password) = envoy.get("POSTGRES_PASSWORD")

  let assert Ok(priv_dir) = wisp.priv_directory("server")
  let static_dir = priv_dir <> "/static"

  let db =
    pog.default_config()
    |> pog.host(host)
    |> pog.database(database)
    |> pog.user(username)
    |> pog.password(Some(password))
    |> pog.connect

  let handler = router.handle_request(_, db, static_dir)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret)
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  process.sleep_forever()
}
