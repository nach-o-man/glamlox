import gleam/int
import gleam/list
import gleam/string
import gleam/string_tree
import token

type ScannedToken {
  Single(tp: token.TokenType, lexeme: String)
  Double(tp: token.TokenType, lexeme: String)
  Ignored
  NewLine
  Comment
  CommentBlock
  String
  Number(first: String)
  Identifier(first: String)
  Unexpected(val: String, line: Int)
}

pub fn scan_tokens(source: String) -> List(token.Token) {
  let #(scanned, line) = scan_tokens_inner(source, [], 0)

  list.append(scanned, [token.eof(line)])
}

fn scan_tokens_inner(
  source: String,
  scanned_tokens: List(token.Token),
  line: Int,
) -> #(List(token.Token), Int) {
  case source {
    "" -> #(scanned_tokens, line)
    _ -> {
      let #(new_token, rest_source, new_line) = scan_token(source, line)

      let scanned_tokens = case new_token {
        Ok(token) -> list.append(scanned_tokens, [token])
        _ -> scanned_tokens
      }
      scan_tokens_inner(rest_source, scanned_tokens, new_line)
    }
  }
}

fn scan_token(
  source: String,
  line: Int,
) -> #(Result(token.Token, Nil), String, Int) {
  let assert Ok(#(first, rest)) = string.pop_grapheme(source)
  let scanned_token = case first {
    "(" -> Single(token.LeftParen, first)
    ")" -> Single(token.RightParen, first)
    "{" -> Single(token.LeftBrace, first)
    "}" -> Single(token.RightBrace, first)
    "," -> Single(token.Comma, first)
    "." -> Single(token.Dot, first)
    "-" -> Single(token.Minus, first)
    "+" -> Single(token.Plus, first)
    ";" -> Single(token.Semicolon, first)
    "*" -> Single(token.Star, first)
    "!" ->
      ternary(
        match_next(rest, "="),
        Double(token.BangEqual, "!="),
        Single(token.Bang, first),
      )
    "=" ->
      ternary(
        match_next(rest, "="),
        Double(token.EqualEqual, "=="),
        Single(token.Equal, first),
      )
    ">" ->
      ternary(
        match_next(rest, "="),
        Double(token.GreaterEqual, ">="),
        Single(token.Greater, first),
      )
    "<" ->
      ternary(
        match_next(rest, "="),
        Double(token.LessEqual, "<="),
        Single(token.Less, first),
      )
    "/" ->
      ternary(
        match_next(rest, "/"),
        Comment,
        ternary(match_next(rest, "*"), CommentBlock, Single(token.Slash, first)),
      )
    " " | "\r" | "\t" -> Ignored
    "\n" -> NewLine
    "\"" -> String
    _ as other -> {
      case is_digit(other) {
        True -> Number(other)
        False -> {
          case is_alpha(other) {
            True -> Identifier(other)
            False -> Unexpected(other, line)
          }
        }
      }
    }
  }

  process_scanned_token(scanned_token, rest, line)
}

fn line_shift(source: String) -> Int {
  list.count(string.to_graphemes(source), fn(str) { str == "\n" })
}

fn process_scanned_token(
  scanned_token: ScannedToken,
  source: String,
  line,
) -> #(Result(token.Token, Nil), String, Int) {
  case scanned_token {
    Single(tp, lex) -> {
      let token = token.single(tp, lex, line)
      #(Ok(token), source, line)
    }
    Double(tp, lex) -> {
      let token = token.double(tp, lex, line)
      // since second symbol of token is in the source
      let new_rest = string.drop_start(source, 1)
      #(Ok(token), new_rest, line)
    }
    Comment -> {
      case string.split_once(source, "\n") {
        Error(_) -> #(Error(Nil), "", line)
        Ok(#(_left, right)) -> #(Error(Nil), right, line + 1)
      }
    }
    CommentBlock -> {
      case string.split_once(source, "*/") {
        Error(_) -> panic as "Unterminated comment block"
        Ok(#(left, right)) -> {
          let new_line = line_shift(left) + line
          #(Error(Nil), right, new_line)
        }
      }
    }
    NewLine -> {
      #(Error(Nil), source, line + 1)
    }
    String -> {
      case string.split_once(source, "\"") {
        Error(_) -> panic as "Unterminated string"
        Ok(#(left, right)) -> {
          let new_line = line_shift(left) + line
          let token = token.string("\"" <> left <> "\"", left, new_line)
          #(Ok(token), right, new_line)
        }
      }
    }
    Number(start) -> {
      let #(result, rest_source) =
        read_number(source, string_tree.from_string(start))
      let token = token.number(result, line)
      #(Ok(token), rest_source, line)
    }
    Identifier(start) -> {
      let #(maybe_keyword, rest_source) =
        read_identifier(source, string_tree.from_string(start))
      let token = case check_keyword(maybe_keyword) {
        Ok(keyword_type) -> token.keyword(keyword_type, maybe_keyword, line)
        Error(_) -> token.identifier(maybe_keyword, line)
      }
      #(Ok(token), rest_source, line)
    }
    Ignored -> #(Error(Nil), source, line)
    Unexpected(data, line) ->
      panic as {
        "Unexpected character on line " <> int.to_string(line) <> " : " <> data
      }
  }
}

fn read_identifier(
  source: String,
  accumulator: string_tree.StringTree,
) -> #(String, String) {
  let tested = string.pop_grapheme(source)
  case tested {
    Error(_) -> #(string_tree.to_string(accumulator), source)
    Ok(#(maybe_alphanumeric, rest_source)) -> {
      case is_alphanumeric(maybe_alphanumeric) {
        True ->
          read_identifier(
            rest_source,
            string_tree.append(accumulator, maybe_alphanumeric),
          )
        False -> #(string_tree.to_string(accumulator), source)
      }
    }
  }
}

fn read_number(
  source: String,
  accumulator: string_tree.StringTree,
) -> #(String, String) {
  let tested = string.pop_grapheme(source)
  case tested {
    Error(_) -> #(string_tree.to_string(accumulator), source)
    Ok(#(maybe_digit, rest_source)) -> {
      case is_digit(maybe_digit) {
        True ->
          read_number(rest_source, string_tree.append(accumulator, maybe_digit))
        False -> {
          case maybe_digit {
            "." ->
              case string.first(rest_source) {
                Error(_) -> #(string_tree.to_string(accumulator), source)
                Ok(_) ->
                  read_number(
                    rest_source,
                    string_tree.append(accumulator, maybe_digit),
                  )
              }
            _ -> #(string_tree.to_string(accumulator), source)
          }
        }
      }
    }
  }
}

fn match_next(source: String, expected: String) -> Bool {
  case string.first(source) {
    Error(_) -> False
    Ok(data) -> data == expected
  }
}

fn ternary(condition: Bool, true_result: value, false_result: value) -> value {
  case condition {
    True -> true_result
    False -> false_result
  }
}

fn is_digit(source: String) -> Bool {
  case assert_single_character(source) {
    "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "0" -> True
    _ -> False
  }
}

fn is_alpha(source: String) -> Bool {
  case assert_single_character(source) {
    "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z"
    | "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z"
    | "_" -> True
    _ -> False
  }
}

fn is_alphanumeric(source: String) -> Bool {
  is_digit(source) || is_alpha(source)
}

fn check_keyword(source: String) -> Result(token.TokenType, Nil) {
  case source {
    "and" -> Ok(token.And)
    "class" -> Ok(token.Class)
    "else" -> Ok(token.Else)
    "false" -> Ok(token.False)
    "for" -> Ok(token.For)
    "fun" -> Ok(token.Fun)
    "if" -> Ok(token.If)
    "nil" -> Ok(token.Nil)
    "or" -> Ok(token.Or)
    "print" -> Ok(token.Print)
    "return" -> Ok(token.Return)
    "super" -> Ok(token.Super)
    "this" -> Ok(token.This)
    "true" -> Ok(token.True)
    "var" -> Ok(token.Var)
    "while" -> Ok(token.While)
    _ -> Error(Nil)
  }
}

fn assert_single_character(maybe_single: String) -> String {
  case string.length(maybe_single) {
    1 -> maybe_single
    _ -> panic as "function should be called with with single length string"
  }
}
