import gleam/dict
import gleam/result
import lox
import token

type Name =
  String

type Value =
  lox.LoxType

type Token =
  token.Token

pub type Environment =
  dict.Dict(Name, Value)

pub fn new() -> Environment {
  dict.new()
}

pub fn define(env: Environment, name: Name, value: Value) -> Environment {
  dict.insert(env, name, value)
}

pub fn assign(
  env: Environment,
  name: Name,
  value: Value,
) -> Result(Environment, String) {
  case dict.has_key(env, name) {
    True -> define(env, name, value) |> Ok
    False -> { "Undefined variable '" <> name <> "'." } |> Error
  }
}

pub fn get(env: Environment, tkn: Token) -> Result(Value, String) {
  let name = token.lexeme(tkn)
  dict.get(env, name)
  |> result.try_recover(fn(_) {
    { "Undefined variable '" <> name <> "'." } |> Error
  })
}
