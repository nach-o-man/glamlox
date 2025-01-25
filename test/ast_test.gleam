import ast
import expr
import gleeunit/should
import token

pub fn ast_print_test() {
  let input =
    expr.Binary(
      expr.Unary(token.single(token.Minus, "-", 1), expr.IntLiteral(123)),
      token.single(token.Star, "*", 1),
      expr.Grouping(expr.FloatLiteral(45.67)),
    )
  ast.print_expr(input) |> should.equal("(* (- 123) (group 45.67))")
}
