import gleam/list
import gleam/option
import gleam/string
import token

type ScannedToken {
  Single(tp: token.TokenType)
  Double(tp: token.TokenType)
  Unknown
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
      let #(new_token, rest_graphemes, new_line) = scan_token(graphemes, line)

      let scanned_tokens = case new_token {
        option.Some(token) -> list.append(scanned_tokens, [token])
        _ -> scanned_tokens
      }
      scan_tokens_inner(rest_graphemes, scanned_tokens, new_line)
    }
  }
}

fn scan_token(
  graphemes: List(String),
  line: Int,
) -> #(option.Option(token.Token), List(String), Int) {
  let assert Ok(first) = list.first(graphemes)
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
    "!" -> try_match_next(graphemes, "=", token.BangEqual, token.Bang)
    "=" -> try_match_next(graphemes, "=", token.EqualEqual, token.Equal)
    ">" -> try_match_next(graphemes, "=", token.GreaterEqual, token.Greater)
    "<" -> try_match_next(graphemes, "=", token.LessEqual, token.Less)
    _ -> Unknown
  }

  case scanned_token {
    Single(token_type) -> {
      let #(left, right) = list.split(graphemes, 1)
      #(add_token(token_type, left, line), right, 1)
    }
    Double(token_type) -> {
      let #(left, right) = list.split(graphemes, 2)
      #(add_token(token_type, left, line), right, 2)
    }
    _ -> #(option.None, list.drop(graphemes, 1), 1)
  }
}

fn match_next(graphemes: List(String), expected: String) -> Bool {
  let graphemes = list.rest(graphemes)
  case graphemes {
    Error(_) -> False
    Ok(data) -> {
      let assert Ok(next) = list.first(data)
      next == expected
    }
  }
}

fn try_match_next(
  graphemes: List(String),
  expected: String,
  true_result: token.TokenType,
  false_result: token.TokenType,
) -> ScannedToken {
  let match_result = match_next(graphemes, expected)
  case match_result {
    True -> Double(true_result)
    False -> Single(false_result)
  }
}

fn add_token(
  tp: token.TokenType,
  graphemes: List(String),
  line: Int,
) -> option.Option(token.Token) {
  option.Some(token.new(tp, string.join(graphemes, ""), option.None, line))
}
