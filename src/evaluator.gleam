import error
import expr
import gleam/bool
import gleam/float
import gleam/int
import gleam/order
import gleam/result
import gleam/string
import token
import token_type

type Token =
  token.Token

type Expr =
  expr.Expr

type EvalResult =
  Result(Expr, error.ExpressionError)

type AllowedOperands {
  NumberPair(Float, Float)
  StringPair(String, String)
  StringFloat(String, Float)
  StringInt(String, Int)
}

type CustomOrder {
  Gt
  GtEq
  LtEq
  Lt
}

pub fn evaluate(expr: Expr) -> EvalResult {
  case expr {
    expr.BoolLiteral(_)
    | expr.FloatLiteral(_)
    | expr.IntLiteral(_)
    | expr.StringLiteral(_)
    | expr.NilLiteral -> Ok(expr)
    expr.Unary(op, r) -> evaluate_unary(op, r)
    expr.Binary(l, op, r) -> evaluate_binary(op, l, r)
    _ -> error.UnsupportedExpression(expr) |> Error
  }
}

fn is_truthy(expr: Expr) -> Bool {
  case expr {
    expr.BoolLiteral(val) -> val
    expr.NilLiteral -> False
    _ -> True
  }
}

fn assert_number(expr: Expr) -> Result(Float, error.ExpressionError) {
  case expr {
    expr.FloatLiteral(value) -> value |> Ok
    expr.IntLiteral(value) -> int.to_float(value) |> Ok
    _ -> error.JustMessage("Should be called with number literal.") |> Error
  }
}

fn assert_numbers(
  left: Expr,
  right: Expr,
) -> Result(AllowedOperands, error.ExpressionError) {
  case assert_number(left), assert_number(right) {
    Ok(l), Ok(r) -> NumberPair(l, r) |> Ok
    _, _ -> error.JustMessage("Operation allowed only for 2 numbers") |> Error
  }
}

fn assert_allowed(
  left: Expr,
  right: Expr,
) -> Result(AllowedOperands, error.ExpressionError) {
  case left, right {
    expr.FloatLiteral(l), expr.FloatLiteral(r) -> NumberPair(l, r) |> Ok
    expr.FloatLiteral(l), expr.IntLiteral(r) ->
      NumberPair(l, int.to_float(r)) |> Ok
    expr.IntLiteral(l), expr.FloatLiteral(r) ->
      NumberPair(int.to_float(l), r) |> Ok
    expr.IntLiteral(l), expr.IntLiteral(r) ->
      NumberPair(int.to_float(l), int.to_float(r)) |> Ok
    expr.StringLiteral(l), expr.FloatLiteral(r) -> StringFloat(l, r) |> Ok
    expr.StringLiteral(l), expr.IntLiteral(r) -> StringInt(l, r) |> Ok
    expr.StringLiteral(l), expr.StringLiteral(r) -> StringPair(l, r) |> Ok
    _, _ -> error.JustMessage("Disallowed argument combination") |> Error
  }
}

fn division_by_zero_eq_zero(a: Float, b: Float) -> Float {
  case float.divide(a, b) {
    Ok(val) -> val
    _ -> 0.0
  }
}

fn pipe_to_func(
  pair: AllowedOperands,
  func: fn(Float, Float) -> Float,
) -> EvalResult {
  case pair {
    NumberPair(l, r) -> func(l, r) |> expr.FloatLiteral |> Ok
    _ ->
      error.JustMessage("Shoul be only called for the pair of numbers.")
      |> Error
  }
}

fn expected_order(pair: AllowedOperands, expected: CustomOrder) -> EvalResult {
  let comparison_result = case pair {
    NumberPair(l, r) -> float.compare(l, r) |> Ok
    StringPair(l, r) -> string.compare(l, r) |> Ok
    _ ->
      error.JustMessage("Operands must be two numbers or two strings") |> Error
  }

  let break_tie_and_compare = fn(x) {
    case expected {
      Gt -> order.break_tie(x, order.Eq) == order.Gt
      GtEq -> order.break_tie(x, order.Gt) == order.Gt
      Lt -> order.break_tie(x, order.Eq) == order.Lt
      LtEq -> order.break_tie(x, order.Lt) == order.Lt
    }
    |> expr.BoolLiteral
    |> Ok
  }
  result.try(comparison_result, break_tie_and_compare)
}

fn evaluate_binary(operator: Token, left, right) -> EvalResult {
  let assert Ok(left) = evaluate(left)
  let assert Ok(right) = evaluate(right)

  case token.tp(operator) {
    token_type.Minus ->
      assert_numbers(left, right) |> result.try(pipe_to_func(_, float.subtract))
    token_type.Slash ->
      assert_numbers(left, right)
      |> result.try(pipe_to_func(_, division_by_zero_eq_zero))
    token_type.Star ->
      assert_numbers(left, right) |> result.try(pipe_to_func(_, float.multiply))
    token_type.Plus ->
      result.try(assert_allowed(left, right), fn(allowed) {
        case allowed {
          StringPair(l, r) -> { l <> r } |> expr.StringLiteral |> Ok
          NumberPair(l, r) -> NumberPair(l, r) |> pipe_to_func(float.add)
          StringFloat(l, r) ->
            { l <> float.to_string(r) } |> expr.StringLiteral |> Ok
          StringInt(l, r) ->
            { l <> int.to_string(r) } |> expr.StringLiteral |> Ok
        }
      })
    token_type.Greater ->
      assert_allowed(left, right) |> result.try(expected_order(_, Gt))
    token_type.GreaterEqual ->
      assert_allowed(left, right) |> result.try(expected_order(_, GtEq))
    token_type.EqualEqual -> { left == right } |> expr.BoolLiteral |> Ok
    token_type.BangEqual -> { left != right } |> expr.BoolLiteral |> Ok
    token_type.LessEqual ->
      assert_allowed(left, right) |> result.try(expected_order(_, LtEq))
    token_type.Less ->
      assert_allowed(left, right) |> result.try(expected_order(_, Lt))
    _ -> error.unreacheable_code()
  }
  |> result.try_recover(fn(err) {
    case err {
      error.JustMessage(message) ->
        error.OperationError(operator, message) |> Error
      error.OperationError(op, message) ->
        error.OperationError(op, message) |> Error
      _ -> error.unreacheable_code()
    }
  })
}

fn evaluate_unary(operator: Token, right: Expr) -> EvalResult {
  let assert Ok(right) = evaluate(right)
  case token.tp(operator) {
    token_type.Minus -> {
      case right {
        expr.IntLiteral(i) -> expr.IntLiteral(-i) |> Ok
        expr.FloatLiteral(f) -> f |> float.negate |> expr.FloatLiteral |> Ok
        _ ->
          operator |> error.OperationError("Operand must be number.") |> Error
      }
    }
    token_type.Bang ->
      right |> is_truthy |> bool.negate |> expr.BoolLiteral |> Ok
    _ -> error.unreacheable_code()
  }
}
