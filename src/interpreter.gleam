import ast
import evaluator
import gleam/bool
import gleam/float
import gleam/io
import gleam/string
import lox

type Expr =
  ast.Expr

type LoxType =
  lox.LoxType

pub fn interpret(expr: Expr) {
  case evaluator.evaluate(expr) {
    Ok(value) -> stringify(value) |> io.println
    Error(err) -> panic as err.message
  }
}

fn stringify(value: LoxType) {
  case value {
    lox.LoxBoolean(b) -> bool.to_string(b)
    lox.LoxNumber(fl) -> {
      let str = float.to_string(fl)
      case string.ends_with(str, ".0") {
        True -> string.drop_end(str, 2)
        False -> str
      }
    }
    lox.LoxString(str) -> str
    lox.LoxNil -> "nil"
  }
}
