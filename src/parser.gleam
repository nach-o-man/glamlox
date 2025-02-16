import ast
import error
import token
import token_type

type Token =
  token.Token

type Expr =
  ast.Expr

type TokenList =
  List(Token)

type ParseIteration {
  ParseIteration(left: TokenList, current: Token, rigth: TokenList)
}

type ExpressionIteration =
  #(Expr, ParseIteration)

fn next_iteration(left: TokenList, right: TokenList) -> ParseIteration {
  let assert [new_current, ..new_right] = right
  ParseIteration(left, new_current, new_right)
}

pub fn parse(tokens: TokenList) -> Expr {
  let first_iteration = next_iteration([], tokens)
  let #(result_expr, next_iter) = expr(first_iteration)
  case token.tp(next_iter.current) {
    token_type.Eof -> result_expr
    _ -> error.parse_error(next_iter.current, "Expected expression")
  }
}

fn expr(iteration: ParseIteration) -> ExpressionIteration {
  iteration |> equality_expr
}

fn equality_expr(iteration: ParseIteration) -> ExpressionIteration {
  iteration |> comparison_expr |> equality_expr_recursive
}

fn comparison_expr(iteration: ParseIteration) -> ExpressionIteration {
  iteration |> term_expr |> comparison_expr_recursive
}

fn term_expr(iteration: ParseIteration) -> ExpressionIteration {
  iteration |> factor_expr |> term_expr_recursive
}

fn factor_expr(iteration: ParseIteration) -> ExpressionIteration {
  iteration |> unary_expr |> factor_expr_recursive
}

fn equality_expr_recursive(
  iteration: ExpressionIteration,
) -> ExpressionIteration {
  let #(new_expr, next_iter) = iteration
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.BangEqual | token_type.EqualEqual -> {
      let #(right_expr, next_iter) =
        comparison_expr(next_iteration(left, right))
      equality_expr_recursive(#(
        ast.Binary(new_expr, current, right_expr),
        next_iter,
      ))
    }
    _ -> #(new_expr, next_iter)
  }
}

fn comparison_expr_recursive(
  iteration: ExpressionIteration,
) -> ExpressionIteration {
  let #(new_expr, next_iter) = iteration
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.Greater
    | token_type.GreaterEqual
    | token_type.Less
    | token_type.LessEqual -> {
      let #(right_expr, next_iter) = term_expr(next_iteration(left, right))
      comparison_expr_recursive(#(
        ast.Binary(new_expr, current, right_expr),
        next_iter,
      ))
    }
    _ -> #(new_expr, next_iter)
  }
}

fn term_expr_recursive(iteration: ExpressionIteration) -> ExpressionIteration {
  let #(new_expr, next_iter) = iteration
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.Plus | token_type.Minus -> {
      let #(right_expr, next_iter) = factor_expr(next_iteration(left, right))
      term_expr_recursive(#(
        ast.Binary(new_expr, current, right_expr),
        next_iter,
      ))
    }
    _ -> #(new_expr, next_iter)
  }
}

fn factor_expr_recursive(iteration: ExpressionIteration) -> ExpressionIteration {
  let #(new_expr, next_iter) = iteration
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.Slash | token_type.Star -> {
      let #(right_expr, next_iter) = unary_expr(next_iteration(left, right))
      factor_expr_recursive(#(
        ast.Binary(new_expr, current, right_expr),
        next_iter,
      ))
    }
    _ -> #(new_expr, next_iter)
  }
}

fn unary_expr(iteration: ParseIteration) -> ExpressionIteration {
  let ParseIteration(left, current, right) = iteration
  case token.tp(current) {
    token_type.Bang | token_type.Minus -> {
      let #(new_expr, next_iter) = unary_expr(next_iteration(left, right))
      #(ast.Unary(current, new_expr), next_iter)
    }
    _ -> primary_expr(iteration)
  }
}

fn primary_expr(iteration: ParseIteration) -> ExpressionIteration {
  let ParseIteration(left, current, right) = iteration
  case token.tp(current) {
    token_type.False -> #(ast.BoolLiteral(False), next_iteration(left, right))
    token_type.True -> #(ast.BoolLiteral(True), next_iteration(left, right))
    token_type.Nil -> #(ast.NilLiteral, next_iteration(left, right))
    token_type.Number | token_type.String -> {
      let found_expr = case token.get_value(current) {
        #(Ok(int), _, _) -> ast.IntLiteral(int)
        #(_, Ok(fl), _) -> ast.FloatLiteral(fl)
        #(_, _, Ok(str)) -> ast.StringLiteral(str)
        #(_, _, _) ->
          error.parse_error(
            current,
            "Illegal call to the token.get_value function",
          )
      }
      #(found_expr, next_iteration(left, right))
    }
    token_type.LeftParen -> {
      let #(inner, next_iter) = expr(next_iteration(left, right))
      let ParseIteration(left, maybe_right_paren, right) = next_iter
      case token.tp(maybe_right_paren) {
        token_type.RightParen -> #(
          ast.Grouping(inner),
          next_iteration(left, right),
        )
        _ ->
          error.parse_error(maybe_right_paren, "Expect ')' after expression.")
      }
    }
    _ -> error.parse_error(current, "Expected expression")
  }
}
