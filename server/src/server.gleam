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

  let assert Ok(_) =
    pog.query(
      "create table if not exists admins (
  id serial primary key,
  username text not null,
  password text not null,
  passphrase text not null",
    )
    |> pog.execute(db)

  let assert Ok(_) =
    pog.query(
      "insert into admins (id, username, password, passphrase) values (
      1,
      'badatmultiplegamesgetbetter',
      'UGF*DSG@YEG&FDSAYFGDY&F&D&^Ffdsug76r1usdycf7tDASYHDFS',
      'oof$nh@mr161sapramu'
    ) on conflict do nothing",
    )
    |> pog.execute(db)

  let handler = router.handle_request(_, db, static_dir)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(80)
    |> mist.start_http

  process.sleep_forever()
}
