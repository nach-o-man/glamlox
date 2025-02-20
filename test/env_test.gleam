import env
import gleeunit/should
import lox
import token

pub fn environment_test() {
  let environment = env.new()
  let name = "A"
  let tkn = token.identifier(name, 0)
  let first_value = lox.LoxString("B")
  let second_value = lox.LoxNumber(42.0)

  env.get(environment, tkn)
  |> should.be_error
  |> should.equal("Undefined variable '" <> name <> "'.")

  let environment = env.define(environment, name, first_value)
  env.get(environment, tkn) |> should.be_ok |> should.equal(first_value)

  let environment = env.define(environment, name, second_value)
  env.get(environment, tkn) |> should.be_ok |> should.equal(second_value)
}
