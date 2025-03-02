import gleam/dict
import gleam/option
import gleam/result
import lox
import token

type Name =
  String

type Value =
  lox.LoxType

type Token =
  token.Token

pub opaque type Environment {
  Environment(
    self: dict.Dict(Name, Value),
    enclosing: option.Option(Environment),
  )
}

pub fn empty() -> Environment {
  new(option.None)
}

pub fn new(enclosing: option.Option(Environment)) -> Environment {
  Environment(dict.new(), enclosing)
}

pub fn define(env: Environment, name: Name, value: Value) -> Environment {
  Environment(dict.insert(env.self, name, value), env.enclosing)
}

fn undefined_var_error(name: Name) -> Result(_, Name) {
  { "Undefined variable '" <> name <> "'." } |> Error
}

pub fn assign(
  env: Environment,
  name: Name,
  value: Value,
) -> Result(Environment, Name) {
  case dict.has_key(env.self, name) {
    True -> define(env, name, value) |> Ok
    False -> {
      case env.enclosing {
        option.Some(enc) -> {
          case assign(enc, name, value) {
            Ok(new_enc) ->
              new_enc |> option.Some |> Environment(env.self, _) |> Ok
            Error(err) -> err |> Error
          }
        }
        option.None -> undefined_var_error(name)
      }
    }
  }
}

pub fn get(env: Environment, tkn: Token) -> Result(Value, Name) {
  let name = token.lexeme(tkn)

  let result =
    dict.get(env.self, name)
    |> result.try_recover(fn(_) { undefined_var_error(name) })

  case result {
    Ok(value) -> Ok(value)
    Error(_) ->
      case env.enclosing {
        option.Some(enc) -> get(enc, tkn)
        option.None -> undefined_var_error(name)
      }
  }
}
