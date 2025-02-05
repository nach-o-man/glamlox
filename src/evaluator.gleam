import error
import expr
import gleam/bool
import gleam/erlang/os
import gleam/float
import gleam/int
import gleam/io
import token
import token_type

type Token =
  token.Token

type Expr =
  expr.Expr

type EvalResult =
  Result(Expr, error.ExpressionError)

pub fn evaluate(expr: Expr) -> EvalResult {
  case expr {
    expr.BoolLiteral(_)
    | expr.FloatLiteral(_)
    | expr.IntLiteral(_)
    | expr.StringLiteral(_)
    | expr.NilLiteral -> Ok(expr)
    expr.Unary(op, r) -> evaluate_unary(op, r)
    expr.Binary(l, op, r) -> evaluate_binary(op, l, r)
    _ -> {
      io.debug(expr)
      todo
    }
  }
}

fn is_truthy(expr: Expr) -> Bool {
  case expr {
    expr.BoolLiteral(val) -> val
    expr.NilLiteral -> False
    _ -> True
  }
}

fn evaluate_binary(operator: Token, left, right) -> EvalResult {
  let assert Ok(left) = evaluate(left)
  let assert Ok(right) = evaluate(right)

  let math_func = case token.tp(operator) {
    token_type.Minus -> #(float.subtract, int.subtract)
    token_type.Slash -> #(
      fn(a, b) {
        case float.divide(a, b) {
          Ok(val) -> val
          _ -> 0.0
        }
      },
      fn(a, b) {
        case int.divide(a, b) {
          Ok(val) -> val
          _ -> 0
        }
      },
    )
    token_type.Star -> #(float.multiply, int.multiply)
    _ -> {
      io.debug(left)
      io.debug(operator)
      io.debug(right)
      todo
    }
  }
  case left, right {
    expr.FloatLiteral(f1), expr.FloatLiteral(f2) ->
      math_func.0(f1, f2) |> expr.FloatLiteral |> Ok
    expr.IntLiteral(i1), expr.FloatLiteral(f2) ->
      i1 |> int.to_float |> math_func.0(f2) |> expr.FloatLiteral |> Ok
    expr.FloatLiteral(f1), expr.IntLiteral(i2) ->
      i2 |> int.to_float |> math_func.0(f1, _) |> expr.FloatLiteral |> Ok
    expr.IntLiteral(i1), expr.IntLiteral(i2) ->
      math_func.1(i1, i2) |> expr.IntLiteral |> Ok
    _, _ -> todo
  }
}

fn evaluate_unary(operator: Token, right: Expr) -> EvalResult {
  let assert Ok(right) = evaluate(right)
  case token.tp(operator) {
    token_type.Minus -> {
      case right {
        expr.IntLiteral(i) -> expr.IntLiteral(-i) |> Ok
        expr.FloatLiteral(f) -> f |> float.negate |> expr.FloatLiteral |> Ok
        _ -> operator |> error.Unary("Operand must be number.") |> Error
      }
    }
    token_type.Bang ->
      right |> is_truthy |> bool.negate |> expr.BoolLiteral |> Ok
    _ -> {
      io.debug(operator)
      io.debug(right)
      todo
    }
  }
}
