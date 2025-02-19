import ast
import evaluator
import gleam/bool
import gleam/float
import gleam/io
import gleam/list
import gleam/string
import lox

type Expr =
  ast.Expr

type Stmt =
  ast.Stmt

type LoxType =
  lox.LoxType

type StatementList =
  List(Stmt)

pub fn interpret(statements: StatementList) {
  list.each(statements, fn(stmt) {
    case stmt {
      ast.Print(expr) -> {
        evaluate(expr) |> io.println
        Nil
      }
      ast.Expression(expr) -> {
        evaluate(expr)
        Nil
      }
    }
  })
}

fn evaluate(expr: Expr) -> String {
  case evaluator.evaluate(expr) {
    Ok(value) -> stringify(value)
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
