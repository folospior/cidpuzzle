import wisp

pub fn middleware(
  req: wisp.Request,
  static_directory: String,
  handle_rest: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, "/static", static_directory)

  handle_rest(req)
}
