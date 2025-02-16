import ast
import error
import gleam/bool
import gleam/float
import gleam/int
import gleam/order
import gleam/result
import gleam/string
import lox
import token
import token_type

type Token =
  token.Token

type Expr =
  ast.Expr

type LoxType =
  lox.LoxType

type LoxResult =
  Result(LoxType, error.ExpressionError)

pub fn evaluate(expr: Expr) -> LoxResult {
  case expr {
    ast.BoolLiteral(bool) -> lox.LoxBoolean(bool) |> Ok
    ast.FloatLiteral(fl) -> lox.LoxNumber(fl) |> Ok
    ast.IntLiteral(i) -> lox.LoxNumber(int.to_float(i)) |> Ok
    ast.StringLiteral(s) -> lox.LoxString(s) |> Ok
    ast.NilLiteral -> lox.LoxNil |> Ok
    ast.Unary(op, r) -> evaluate_unary(op, r)
    ast.Binary(l, op, r) -> evaluate_binary(op, l, r)
    _ -> error.UnsupportedExpression("Unsupported expression", expr) |> Error
  }
}

fn is_truthy(value: LoxType) -> Bool {
  case value {
    lox.LoxBoolean(val) -> val
    lox.LoxNil -> False
    _ -> True
  }
}

fn evaluate_binary(operator: Token, left: Expr, right: Expr) -> LoxResult {
  let left = evaluate(left)
  let right = evaluate(right)

  case result.all([left, right]) {
    Ok(values) ->
      case values {
        [lox.LoxNumber(left), lox.LoxNumber(right)] ->
          evaluate_binary_number_number(operator, left, right)
        [lox.LoxString(left), lox.LoxString(right)] ->
          evaluate_binary_string_string(operator, left, right)
        [lox.LoxString(left), lox.LoxNumber(right)] ->
          evaluate_binary_string_number(operator, left, right)
        [left, right] -> {
          case token.tp(operator) {
            token_type.EqualEqual -> { left == right } |> lox.LoxBoolean |> Ok
            token_type.BangEqual -> { left != right } |> lox.LoxBoolean |> Ok
            _ ->
              error.OperationError(
                "Operation is not applicable for arguments",
                operator,
              )
              |> Error
          }
        }
        _ -> error.OperationError("Unsupported operation", operator) |> Error
      }
    Error(err) -> Error(err)
  }
}

fn evaluate_binary_string_number(
  operator: Token,
  left: String,
  right: Float,
) -> LoxResult {
  case token.tp(operator) {
    token_type.Plus -> { left <> float.to_string(right) } |> lox.LoxString |> Ok
    _ ->
      error.OperationError(
        "Operation is not applicable for arguments string-number",
        operator,
      )
      |> Error
  }
}

fn evaluate_binary_number_number(
  operator: Token,
  left: Float,
  right: Float,
) -> LoxResult {
  case token.tp(operator) {
    token_type.Minus -> { left -. right } |> lox.LoxNumber |> Ok
    token_type.Slash -> { left /. right } |> lox.LoxNumber |> Ok
    token_type.Star -> { left *. right } |> lox.LoxNumber |> Ok
    token_type.Plus -> { left +. right } |> lox.LoxNumber |> Ok
    token_type.Greater -> { left >. right } |> lox.LoxBoolean |> Ok
    token_type.GreaterEqual -> { left >=. right } |> lox.LoxBoolean |> Ok
    token_type.Less -> { left <. right } |> lox.LoxBoolean |> Ok
    token_type.LessEqual -> { left <=. right } |> lox.LoxBoolean |> Ok
    token_type.EqualEqual -> { left == right } |> lox.LoxBoolean |> Ok
    token_type.BangEqual -> { left != right } |> lox.LoxBoolean |> Ok
    _ ->
      error.OperationError(
        "Operation is not applicable for arguments number-number",
        operator,
      )
      |> Error
  }
}

fn evaluate_binary_string_string(
  operator: Token,
  left: String,
  right: String,
) -> LoxResult {
  case token.tp(operator) {
    token_type.Plus -> { left <> right } |> lox.LoxString |> Ok
    token_type.Greater ->
      { string.compare(left, right) == order.Gt }
      |> lox.LoxBoolean
      |> Ok
    token_type.GreaterEqual ->
      { order.break_tie(string.compare(left, right), order.Gt) == order.Gt }
      |> lox.LoxBoolean
      |> Ok
    token_type.Less ->
      { string.compare(left, right) == order.Lt }
      |> lox.LoxBoolean
      |> Ok
    token_type.LessEqual ->
      { order.break_tie(string.compare(left, right), order.Lt) == order.Lt }
      |> lox.LoxBoolean
      |> Ok
    token_type.EqualEqual -> { left == right } |> lox.LoxBoolean |> Ok
    token_type.BangEqual -> { left != right } |> lox.LoxBoolean |> Ok
    _ ->
      error.OperationError(
        "Operation is not applicable for arguments string-string",
        operator,
      )
      |> Error
  }
}

fn evaluate_unary(operator: Token, right: Expr) -> LoxResult {
  let assert Ok(right) = evaluate(right)
  case token.tp(operator) {
    token_type.Minus -> {
      case right {
        lox.LoxNumber(f) -> f |> float.negate |> lox.LoxNumber |> Ok
        _ -> error.OperationError("Operand must be number.", operator) |> Error
      }
    }
    token_type.Bang -> right |> is_truthy |> bool.negate |> lox.LoxBoolean |> Ok
    _ -> error.unreacheable_code()
  }
}
