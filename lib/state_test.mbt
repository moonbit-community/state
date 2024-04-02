test "new" {
  let state : State[Int, Int] = State::new(10)
  @assertion.assert_eq(run_state(state, 0), (10, 0))?
}

test "state" {
  let state : State[Int, Int] = state(fn { x => (x + 1, x + 1) })
  @assertion.assert_eq(run_state(state, 0), (1, 1))?
}

test "get" {
  let state : State[Int, Int] = State::new(10) |> bind(fn { _ => get() })
  @assertion.assert_eq(run_state(state, 20), (20, 20))?
}

test "put" {
  let state : State[Int, Unit] = State::new(10) |> bind(fn { _ => put(20) })
  @assertion.assert_eq(run_state(state, 0), ((), 20))?
}

test "map" {
  let state : State[Int, Int] = State::new(10) |> map(fn { x => x + 1 })
  @assertion.assert_eq(run_state(state, 0), (11, 0))?
}

test "modify" {
  let state : State[Int, Int] = State::new(0)
    |> bind(fn { _ => modify(fn { x => x + 1 }) })
    |> bind(fn { _ => get() })
  @assertion.assert_eq(run_state(state, 0), (1, 1))?
}

test "bind" {
  let state : State[Int, Int] = State::new(10)
    |> bind(fn { _ => put(20) })
    |> bind(fn { _ => get() |> bind(fn { x => new(x + 1) }) })
  @assertion.assert_eq(run_state(state, 0), (21, 20))?
}

test "run_state" {
  let state : State[Int, Int] = State::new(10)
  @assertion.assert_eq(run_state(state, 0), (10, 0))?
}

test "eval_state" {
  let state : State[Int, Int] = State::new(10)
    |> bind(fn { _ => put(20) })
    |> bind(fn { _ => get() |> bind(fn { x => new(x + 1) }) })
  @assertion.assert_eq(eval_state(state, 0), 21)?
}

test "exec_state" {
  let state : State[Int, Unit] = State::new(10) |> bind(fn { _ => put(20) })
  @assertion.assert_eq(exec_state(state, 0), 20)?
}

test "state_stack" {
  fn push(n : Int) -> State[List[Int], Int] {
    { runState: fn(ns : List[Int]) { (n, Cons(n, ns)) } }
  }

  fn pop() -> State[List[Int], Int] {
    {
      runState: fn(ns : List[Int]) {
        match ns {
          Cons(n, ns) => (n, ns)
          Nil => abort("empty stack")
        }
      },
    }
  }

  fn plus() -> State[List[Int], Int] {
    bind(pop(), fn(n1) { bind(pop(), fn(n2) { push(n1 + n2) }) })
  }

  fn mult() -> State[List[Int], Int] {
    bind(pop(), fn(n1) { bind(pop(), fn(n2) { push(n1 * n2) }) })
  }

  let prog : State[List[Int], Int] = push(2)
    |> bind(fn { _ => push(3) })
    |> bind(fn { _ => push(5) })
    |> bind(fn { _ => plus() })
    |> bind(fn { _ => mult() })
  @assertion.assert_eq(run_state(prog, Nil), (16, Cons(16, Nil)))?
  let prog2 : State[List[Int], String] = State::new(10)
    |> bind(fn { x => push(3 + x) })
    |> bind(fn { _ => push(5) })
    |> bind(fn { _ => mult() })
    |> map(fn { x => x.to_string() })
  @assertion.assert_eq(eval_state(prog2, Nil), "65")?
  let prog3 = push(2) |> bind(fn { _ => push(3) }) |> bind(fn { _ => get() })
  @assertion.assert_eq(eval_state(prog3, Nil), Cons(3, Cons(2, Nil)))?
  let prog4 = State::new(0)
    |> bind(fn { _ => put(123) })
    |> bind(fn { _ => get() })
  @assertion.assert_eq(run_state(prog4, 0), (123, 123))?
  let prog5 : State[List[Int], Int] = State::new(5)
  @assertion.assert_eq(eval_state(prog5, Nil), 5)?
  let prog6 : State[List[Int], Int] = push(2)
    |> bind(fn { _ => modify(fn { x => Cons(100, x) }) })
    |> bind(fn { _ => mult() })
  @assertion.assert_eq(run_state(prog6, Nil), (200, Cons(200, Nil)))?
}

test "tick_state" {
  fn tick() -> State[Int, Int] {
    get().bind(fn { x => put(x + 1).bind(fn { _ => new(x) }) })
  }

  for i = 0; i < 100; i = i + 1 {
    @assertion.assert_eq(exec_state(tick(), i), i + 1)?
  }
}
