import ast
import gleeunit/should
import token

pub fn ast_print_test() {
  let input =
    ast.Binary(
      ast.Unary(token.single(token.Minus, "-", 1), ast.IntLiteral(123)),
      token.single(token.Star, "*", 1),
      ast.Grouping(ast.FloatLiteral(45.67)),
    )
  ast.print_expr(input) |> should.equal("(* (- 123) (group 45.67))")
}
