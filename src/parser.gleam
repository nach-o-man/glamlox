import ast
import error
import gleam/list
import token
import token_type

type Token =
  token.Token

type Expr =
  ast.Expr

type Statement =
  Result(ast.Stmt, String)

type TokenList =
  List(Token)

type StatementList =
  List(Statement)

type ParseIteration {
  ParseIteration(left: TokenList, current: Token, right: TokenList)
}

type ExpressionIteration =
  #(Expr, ParseIteration)

type StatementIteration =
  #(Statement, ParseIteration)

fn next_iteration(left: TokenList, right: TokenList) -> ParseIteration {
  let assert [new_current, ..new_right] = right
  ParseIteration(left, new_current, new_right)
}

fn consume_current(iteration: ParseIteration) -> ParseIteration {
  next_iteration(iteration.left, iteration.right)
}

pub fn parse(tokens: TokenList) -> StatementList {
  let first_iteration = next_iteration([], tokens)
  parse_recursive(first_iteration, [])
}

fn parse_recursive(
  iteration: ParseIteration,
  statements: StatementList,
) -> StatementList {
  case token.tp(iteration.current) {
    token_type.Eof -> list.reverse(statements)
    _ -> {
      let #(statement, next_iter) = declaration(iteration)
      let synchronised_iteration = case statement {
        Ok(_) -> next_iter
        Error(_) -> synchronise(next_iter)
      }

      parse_recursive(synchronised_iteration, [statement, ..statements])
    }
  }
}

fn declaration(iteration: ParseIteration) -> StatementIteration {
  case token.tp(iteration.current) {
    token_type.Var -> var_declaration(consume_current(iteration))
    _ -> stmt(iteration)
  }
}

fn var_declaration(iteration: ParseIteration) -> StatementIteration {
  let maybe_name = iteration.current
  case token.tp(maybe_name) {
    token_type.Identifier -> {
      let name = maybe_name
      let next_iter = consume_current(iteration)
      let #(initializer, after_init_iter) = case token.tp(next_iter.current) {
        token_type.Equal -> expr(consume_current(next_iter))
        _ -> #(ast.NilLiteral, next_iter)
      }
      case token.tp(after_init_iter.current) {
        token_type.Semicolon -> #(
          ast.Var(name, initializer) |> Ok,
          consume_current(after_init_iter),
        )
        _ -> #("Expect ';' after variable declaration." |> Error, iteration)
      }
    }
    _ -> #("Expected variable name." |> Error, iteration)
  }
}

fn stmt(iteration: ParseIteration) -> StatementIteration {
  let next_iter = consume_current(iteration)
  case token.tp(iteration.current) {
    token_type.Print -> print_stmt(next_iter)
    _ -> expr_stmt(iteration)
  }
}

fn print_stmt(iteration: ParseIteration) -> StatementIteration {
  let #(expr, next_iter) = expr(iteration)
  case token.tp(next_iter.current) {
    token_type.Semicolon -> #(ast.Print(expr) |> Ok, consume_current(next_iter))
    _ -> #("Expect ';' after value." |> Error, next_iter)
  }
}

fn expr_stmt(iteration: ParseIteration) -> StatementIteration {
  let #(expr, next_iter) = expr(iteration)
  case token.tp(next_iter.current) {
    token_type.Semicolon -> #(
      ast.Expression(expr) |> Ok,
      consume_current(next_iter),
    )
    _ -> #("Expect ';' after value." |> Error, next_iter)
  }
}

fn expr(iteration: ParseIteration) -> ExpressionIteration {
  assignment(iteration)
}

fn assignment(iteration: ParseIteration) -> ExpressionIteration {
  let #(expression, next_iter) = equality_expr(iteration)
  let maybe_equal = next_iter.current
  case token.tp(maybe_equal) {
    token_type.Equal -> {
      let #(value, new_next_iter) = assignment(consume_current(next_iter))
      case expression {
        ast.Variable(name) -> #(ast.Assign(name, value), new_next_iter)
        _ ->
          panic as {
            "Invalid assignment target: " <> token.to_string(maybe_equal)
          }
      }
    }
    _ -> #(expression, next_iter)
  }
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
    token_type.Identifier -> #(
      ast.Variable(current),
      next_iteration(left, right),
    )
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

fn synchronise(iteration: ParseIteration) -> ParseIteration {
  case token.tp(iteration.current) {
    token_type.Eof -> iteration
    token_type.Semicolon -> consume_current(iteration)
    _ -> {
      let next_iter = consume_current(iteration)
      case token.tp(next_iter.current) {
        token_type.Class
        | token_type.Fun
        | token_type.Var
        | token_type.For
        | token_type.If
        | token_type.While
        | token_type.Print
        | token_type.Return -> next_iter
        _ -> synchronise(next_iter)
      }
    }
  }
}
