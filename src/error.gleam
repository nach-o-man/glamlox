import gleam/int
import token
import token_type

pub fn error(line: Int, message: String) {
  report(line, "", message)
}

pub fn parse_error(tkn: token.Token, message: String) {
  let line = token.line(tkn)
  case token.tp(tkn) {
    token_type.Eof -> report(line, " at end", message)
    _ -> report(line, { " at '" <> token.lexeme(tkn) <> "'" }, message)
  }
}

fn report(line: Int, where: String, message: String) {
  panic as {
    "[line " <> int.to_string(line) <> "] Error" <> where <> ": " <> message
  }
}
