import gleam/list
import gleeunit/should
import scanner
import token

pub fn scan_tokens_test() {
  scanner.scan_tokens("     (){},.-+;!!====>=><<=       ")
  |> list.map(fn(token) { token.tp })
  |> should.equal([
    token.LeftParen,
    token.RightParen,
    token.LeftBrace,
    token.RightBrace,
    token.Comma,
    token.Dot,
    token.Minus,
    token.Plus,
    token.Semicolon,
    token.Bang,
    token.BangEqual,
    token.EqualEqual,
    token.Equal,
    token.GreaterEqual,
    token.Greater,
    token.Less,
    token.LessEqual,
    token.Eof,
  ])
}
