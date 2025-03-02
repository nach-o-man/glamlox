import env
import gleam/option
import gleeunit/should
import lox
import token

pub fn environment_test() {
  let environment = env.empty()
  let name = "A"
  let non_existent_name = "I DO NOT EXIST"
  let tkn = token.identifier(name, 0)
  let first_value = lox.LoxString("B")
  let second_value = lox.LoxNumber(42.0)
  let third_value = lox.LoxNumber(420.0)

  env.get(environment, tkn)
  |> should.be_error
  |> should.equal("Undefined variable '" <> name <> "'.")

  let environment = environment |> env.define(name, first_value)
  environment |> env.get(tkn) |> should.be_ok |> should.equal(first_value)

  let environment = environment |> env.define(name, second_value)
  environment |> env.get(tkn) |> should.be_ok |> should.equal(second_value)

  let environment = environment |> env.assign(name, third_value) |> should.be_ok
  environment |> env.get(tkn) |> should.be_ok |> should.equal(third_value)

  environment
  |> env.assign(non_existent_name, third_value)
  |> should.be_error
  |> should.equal("Undefined variable '" <> non_existent_name <> "'.")
}

pub fn enclosing_environment_test() {
  let name = "A"
  let non_existent_name = "I DO NOT EXIST"
  let tkn = token.identifier(name, 0)
  let value = lox.LoxString("inner value")
  let new_value = lox.LoxString("new inner value")

  let environment =
    env.new(env.empty() |> env.define(name, value) |> option.Some)

  environment
  |> env.get(tkn)
  |> should.be_ok
  |> should.equal(value)

  environment
  |> env.assign(non_existent_name, value)
  |> should.be_error
  |> should.equal("Undefined variable '" <> non_existent_name <> "'.")

  environment
  |> env.assign(name, new_value)
  |> should.be_ok
  |> env.get(tkn)
  |> should.be_ok
  |> should.equal(new_value)
}
