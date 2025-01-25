import expr
import gleam/float
import gleam/int
import gleam/string_tree
import token

pub fn print_expr(expr: expr.Expr) -> String {
  case expr {
    expr.NilLiteral -> "nil"
    expr.StringLiteral(val) -> val
    expr.FloatLiteral(val) -> float.to_string(val)
    expr.IntLiteral(val) -> int.to_string(val)
    expr.Grouping(ex) -> parenthesise_recursive("(group", [ex])
    expr.Unary(op, r) -> parenthesise_recursive("(" <> token.lexeme(op), [r])
    expr.Binary(l, op, r) ->
      parenthesise_recursive("(" <> token.lexeme(op), [l, r])
  }
}

fn parenthesise_recursive(accumulator: String, exprs: List(expr.Expr)) -> String {
  let accumulator = string_tree.from_string(accumulator)

  case exprs {
    [] -> accumulator |> string_tree.append(")") |> string_tree.to_string
    [first, ..rest] -> {
      let accumulator =
        accumulator
        |> string_tree.append(" ")
        |> string_tree.append(print_expr(first))
        |> string_tree.to_string
      parenthesise_recursive(accumulator, rest)
    }
  }
}
