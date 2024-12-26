import gleam/list
import gleam/string

pub type Token {
  Word(src: String)
}

pub fn scan_tokens(source: String) -> List(Token) {
  source
  |> string.split(" ")
  |> list.map(fn(str) { string.trim(str) })
  |> list.filter(fn(str) { !string.is_empty(str) })
  |> list.map(fn(str) { Word(str) })
}
