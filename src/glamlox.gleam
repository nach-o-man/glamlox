import argv
import env
import gleam/erlang
import gleam/io
import gleam/string
import interpreter
import parser
import scanner
import simplifile

type Env =
  env.Environment

type PromptConsumer =
  fn(String, Env) -> Env

pub fn main() {
  case argv.load().arguments {
    ["script", script] -> {
      run_file(script)
      Nil
    }
    [] -> {
      repl_header("EVALUATE")
      run_prompt(run, env.new())
    }
    _ -> io.print("Usage: glamlox [script FILE]")
  }
}

fn repl_header(mode: String) {
  let title = "Entering REPL in " <> mode <> " mode. Type 'exit' to exit."
  let title_form = string.repeat("=", string.length(title))
  io.println("")
  io.println(title_form)
  io.println(title)
  io.println(title_form)
}

fn run_file(script: String) {
  let assert Ok(source) = simplifile.read(script)
  run(source, env.new())
}

fn run(source: String, environment: Env) -> Env {
  scanner.scan_tokens(source)
  |> parser.parse
  |> interpreter.interpret(environment)
}

fn run_prompt(consumer: PromptConsumer, environment: Env) {
  let assert Ok(line) = erlang.get_line("~> ")
  case string.trim(line) {
    "exit" -> Nil
    _ -> {
      let new_env = run(line, environment)
      run_prompt(consumer, new_env)
    }
  }
}
