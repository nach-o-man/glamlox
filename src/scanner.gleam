import gleam/list
import gleam/option
import gleam/string
import token

pub opaque type Scanner {
  Scanner(source: String)
}

pub fn new(source: String) -> Scanner {
  Scanner(source)
}

pub fn scan_tokens(source: String) -> List(token.Token) {
  let graphemes = string.to_graphemes(source)
  let #(scanned, line) = scan_tokens_inner(graphemes, [], 0)

  list.append(scanned, [token.new(token.Eof, "", option.None, line)])
}

fn scan_tokens_inner(
  graphemes: List(String),
  scanned: List(token.Token),
  line: Int,
) -> #(List(token.Token), Int) {
  case graphemes {
    [first, ..rest] -> {
      let single_token = scan_token(first, line)
      let scanned = case single_token {
        option.Some(yes) -> list.append(scanned, [yes])
        _ -> scanned
      }
      scan_tokens_inner(rest, scanned, 0)
    }
    [] -> #(scanned, line)
  }
}

fn scan_token(source: String, line: Int) -> option.Option(token.Token) {
  let token_type = case source {
    "(" -> option.Some(token.LeftParen)
    ")" -> option.Some(token.RightParen)
    "{" -> option.Some(token.LeftBrace)
    "}" -> option.Some(token.RightBrace)
    "," -> option.Some(token.Comma)
    "." -> option.Some(token.Dot)
    "-" -> option.Some(token.Minus)
    "+" -> option.Some(token.Plus)
    ";" -> option.Some(token.Semicolon)
    "*" -> option.Some(token.Star)
    _ -> option.None
  }

  case token_type {
    option.Some(token_type) -> single_token(token_type, source, line)
    option.None -> option.None
  }
}

fn single_token(
  tp: token.TokenType,
  lexeme: String,
  line: Int,
) -> option.Option(token.Token) {
  option.Some(token.new(tp, lexeme, option.None, line))
}
