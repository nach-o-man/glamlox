import ast
import gleeunit/should
import token
import token_type

pub fn ast_print_test() {
  let input =
    ast.Binary(
      ast.Unary(token.single(token_type.Minus, "-", 1), ast.IntLiteral(123)),
      token.single(token_type.Star, "*", 1),
      ast.Grouping(ast.FloatLiteral(45.67)),
    )
  ast.print_expr(input) |> should.equal("(* (- 123) (group 45.67))")
}
