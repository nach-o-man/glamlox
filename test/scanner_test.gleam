import gleam/list
import gleeunit/should
import scanner
import token

pub fn scan_single_tokens_test() {
  scanner.scan_tokens("     (){},.-+;=!<>/     ")
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
    token.Equal,
    token.Bang,
    token.Less,
    token.Greater,
    token.Slash,
    token.Eof,
  ])
}

pub fn scan_double_tokens_test() {
  scanner.scan_tokens("     !!====>=><<=   ")
  |> list.map(fn(token) { token.tp })
  |> should.equal([
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

pub fn scan_single_line_comment_test() {
  scanner.scan_tokens(" // I am a comment! \n")
  |> list.map(fn(token) { #(token.tp, token.line) })
  |> should.equal([#(token.Eof, 1)])
}

pub fn scan_newline_test() {
  scanner.scan_tokens(" \n \n ")
  |> list.map(fn(token) { #(token.tp, token.line) })
  |> should.equal([#(token.Eof, 2)])
}
