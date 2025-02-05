import gleam/float
import gleam/int
import gleam/string
import token_type

pub opaque type Token {
  SingleToken(tp: token_type.TokenType, lexeme: String, line: Int)
  DoubleToken(tp: token_type.TokenType, lexeme: String, line: Int)
  IntegerToken(
    tp: token_type.TokenType,
    lexeme: String,
    line: Int,
    literal: Int,
  )
  FloatToken(
    tp: token_type.TokenType,
    lexeme: String,
    line: Int,
    literal: Float,
  )
  StringToken(
    tp: token_type.TokenType,
    lexeme: String,
    line: Int,
    literal: String,
  )
  IdentifierToken(tp: token_type.TokenType, lexeme: String, line: Int)
  KeywordToken(tp: token_type.TokenType, lexeme: String, line: Int)
  EofToken(tp: token_type.TokenType, lexeme: String, line: Int)
}

pub fn tp(token: Token) -> token_type.TokenType {
  token.tp
}

pub fn lexeme(token: Token) -> String {
  token.lexeme
}

pub fn line(token: Token) -> Int {
  token.line
}

pub fn get_bool(token: Token) -> Bool {
  case tp(token) {
    token_type.True -> True
    token_type.False -> False
    _ -> panic as "Should only be called for Boolean token"
  }
}

pub fn get_value(
  token: Token,
) -> #(Result(Int, Nil), Result(Float, Nil), Result(String, Nil)) {
  case token {
    IntegerToken(_tp, _lex, _line, val) -> #(Ok(val), Error(Nil), Error(Nil))
    FloatToken(_tp, _lex, _line, val) -> #(Error(Nil), Ok(val), Error(Nil))
    StringToken(_tp, _lex, _line, val) -> #(Error(Nil), Error(Nil), Ok(val))
    _ -> panic as "Should be only called for Integer/Float/String tokens"
  }
}

pub fn identifier(lexeme: String, line: Int) -> Token {
  IdentifierToken(token_type.Identifier, lexeme, line)
}

pub fn keyword(tp: token_type.TokenType, lexeme: String, line: Int) -> Token {
  case tp {
    token_type.And
    | token_type.Class
    | token_type.Else
    | token_type.False
    | token_type.Fun
    | token_type.For
    | token_type.If
    | token_type.Nil
    | token_type.Or
    | token_type.Print
    | token_type.Return
    | token_type.Super
    | token_type.This
    | token_type.True
    | token_type.Var
    | token_type.While -> KeywordToken(tp, lexeme, line)
    _ ->
      panic as {
        "Unable to build keyword token with type: " <> string.inspect(tp)
      }
  }
}

pub fn single(tp: token_type.TokenType, lexeme: String, line: Int) -> Token {
  case tp {
    token_type.LeftParen
    | token_type.RightParen
    | token_type.LeftBrace
    | token_type.RightBrace
    | token_type.Comma
    | token_type.Dot
    | token_type.Minus
    | token_type.Plus
    | token_type.Semicolon
    | token_type.Slash
    | token_type.Bang
    | token_type.Equal
    | token_type.Greater
    | token_type.Less
    | token_type.Star -> SingleToken(tp, lexeme, line)
    _ ->
      panic as {
        "Unable to build single token with type: " <> string.inspect(tp)
      }
  }
}

pub fn double(tp: token_type.TokenType, lexeme: String, line: Int) -> Token {
  case tp {
    token_type.BangEqual
    | token_type.EqualEqual
    | token_type.GreaterEqual
    | token_type.LessEqual -> DoubleToken(tp, lexeme, line)
    _ ->
      panic as {
        "Unable to build double token with type: " <> string.inspect(tp)
      }
  }
}

pub fn eof(line: Int) -> Token {
  EofToken(token_type.Eof, "", line)
}

pub fn string(lexeme: String, literal: String, line: Int) -> Token {
  StringToken(token_type.String, lexeme, line, literal)
}

pub fn number(lexeme: String, line: Int) -> Token {
  case float.parse(lexeme) {
    Error(_) -> {
      case int.parse(lexeme) {
        Error(_) -> panic as { "Unable to parse number: " <> lexeme }
        Ok(data) -> IntegerToken(token_type.Number, lexeme, line, data)
      }
    }
    Ok(data) -> FloatToken(token_type.Number, lexeme, line, data)
  }
}

pub fn to_string(token: Token) -> String {
  case token {
    SingleToken(tp, lexeme, line)
    | DoubleToken(tp, lexeme, line)
    | IntegerToken(tp, lexeme, line, _literal)
    | FloatToken(tp, lexeme, line, _literal)
    | StringToken(tp, lexeme, line, _literal)
    | IdentifierToken(tp, lexeme, line)
    | KeywordToken(tp, lexeme, line) ->
      string.inspect(tp) <> " " <> lexeme <> " " <> int.to_string(line)
    EofToken(_, _, line) -> "EOF " <> int.to_string(line)
  }
}
