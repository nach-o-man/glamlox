import error
import expr
import gleam/bool
import gleam/float
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
