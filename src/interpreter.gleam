import ast
import env
import evaluator
import gleam/bool
import gleam/float
import gleam/io
import gleam/string
import lox
import token

type Expr =
  ast.Expr

type Stmt =
  ast.Stmt

type LoxType =
  lox.LoxType

type StatementList =
  List(Result(Stmt, String))

type Env =
  env.Environment

pub fn interpret(statements: StatementList, environment: Env) -> Env {
  interpret_recursive(environment, statements)
}

fn interpret_recursive(environment: Env, statements: StatementList) -> Env {
  case statements {
    [] -> environment
    [stmt, ..rest] -> {
      let new_environment = case stmt {
        Ok(value) ->
          case value {
            ast.Print(expr) -> {
              evaluate(expr, environment) |> stringify |> io.println
              environment
            }
            ast.Expression(expr) -> {
              evaluate(expr, environment)
              environment
            }
            ast.Var(tk, expr) -> {
              let name = token.lexeme(tk)
              let value = evaluate(expr, environment)
              env.define(environment, name, value)
            }
          }
        Error(err) -> {
          io.println(err)
          environment
        }
      }
      interpret_recursive(new_environment, rest)
    }
  }
}

fn evaluate(expr: Expr, environment: Env) -> LoxType {
  case evaluator.evaluate(expr, environment) {
    Ok(value) -> value
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
