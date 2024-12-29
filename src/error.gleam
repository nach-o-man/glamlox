import gleam/int

pub fn error(line: Int, message: String) {
  panic as { "[line " <> int.to_string(line) <> "] Error: " <> message }
}
