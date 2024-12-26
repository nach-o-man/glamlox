import gleam/list
import gleam/option
import gleam/string
import token

type ScannedToken {
  Single(tp: token.TokenType)
  Double(tp: token.TokenType, lexeme_tail: String)
  Unknown
}

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
  scanned_tokens: List(token.Token),
  line: Int,
) -> #(List(token.Token), Int) {
  case graphemes {
    [] -> #(scanned_tokens, line)
    _ -> {
      let token = scan_token(graphemes, line)
      let #(scanned_tokens, shift) = case token {
        option.Some(#(new_token, graphemes_read)) -> #(
          list.append(scanned_tokens, [new_token]),
          graphemes_read,
        )
        _ -> #(scanned_tokens, 1)
      }
      let rest = list.drop(graphemes, shift)
      scan_tokens_inner(rest, scanned_tokens, 0)
    }
  }
}

fn scan_token(
  source: List(String),
  line: Int,
) -> option.Option(#(token.Token, Int)) {
  let assert Ok(first) = list.first(source)
  let rest = list.rest(source)
  let scanned_token = case first {
    "(" -> Single(token.LeftParen)
    ")" -> Single(token.RightParen)
    "{" -> Single(token.LeftBrace)
    "}" -> Single(token.RightBrace)
    "," -> Single(token.Comma)
    "." -> Single(token.Dot)
    "-" -> Single(token.Minus)
    "+" -> Single(token.Plus)
    ";" -> Single(token.Semicolon)
    "*" -> Single(token.Star)
    "!" -> match(rest, "=", token.BangEqual, token.Bang)
    "=" -> match(rest, "=", token.EqualEqual, token.Equal)
    ">" -> match(rest, "=", token.GreaterEqual, token.Greater)
    "<" -> match(rest, "=", token.LessEqual, token.Less)
    _ -> Unknown
  }

  case scanned_token {
    Single(token_type) -> option.Some(add_token(token_type, first, line))
    Double(token_type, rest) -> {
      option.Some(add_token(token_type, first <> rest, line))
    }
    _ -> option.None
  }
}

fn match(
  source: Result(List(String), Nil),
  expected: String,
  true_result: token.TokenType,
  false_result: token.TokenType,
) -> ScannedToken {
  case source {
    Error(_) -> Unknown
    Ok(data) -> {
      let assert Ok(first) = list.first(data)
      case first == expected {
        True -> Double(true_result, first)
        False -> Single(false_result)
      }
    }
  }
}

fn add_token(
  tp: token.TokenType,
  lexeme: String,
  line: Int,
) -> #(token.Token, Int) {
  let shift = string.length(lexeme)
  #(token.new(tp, lexeme, option.None, line), shift)
}
