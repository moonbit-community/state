///|
test "new" {
  let state : State[Int, Int] = State::new(10)
  assert_eq(state.run_state(0), (10, 0))
}

///|
test "state" {
  let state : State[Int, Int] = state(fn(x) { (x + 1, x + 1) })
  assert_eq(state.run_state(0), (1, 1))
}

///|
test "get" {
  let state : State[Int, Int] = State::new(10).bind(fn(_) { get() })
  assert_eq(state.run_state(20), (20, 20))
}

///|
test "put" {
  let state : State[Int, Unit] = State::new(10).bind(fn(_) { put(20) })
  assert_eq(state.run_state(0), ((), 20))
}

///|
test "map" {
  let state : State[Int, Int] = State::new(10).map(fn(x) { x + 1 })
  assert_eq(state.run_state(0), (11, 0))
}

///|
test "modify" {
  let state : State[Int, Int] = State::new(0)
    .bind(fn(_) { modify(fn(x) { x + 1 }) })
    .bind(fn(_) { get() })
  assert_eq(state.run_state(0), (1, 1))
}

///|
test "bind" {
  let state : State[Int, Int] = State::new(10)
    .bind(fn(_) { put(20) })
    .bind(fn(_) { get().bind(fn(x) { State::new(x + 1) }) })
  assert_eq(state.run_state(0), (21, 20))
}

///|
test "run_state" {
  let state : State[Int, Int] = State::new(10)
  assert_eq(state.run_state(0), (10, 0))
}

///|
test "eval_state" {
  let state : State[Int, Int] = State::new(10)
    .bind(fn(_) { put(20) })
    .bind(fn(_) { get().bind(fn(x) { State::new(x + 1) }) })
  assert_eq(state.eval_state(0), 21)
}

///|
test "exec_state" {
  let state : State[Int, Unit] = State::new(10).bind(fn(_) { put(20) })
  assert_eq(state.exec_state(0), 20)
}

///|

///|
test "state_stack" {
  fn push(n : Int) -> State[ArrayView[Int], Int] {
    { runState: fn(ns : ArrayView[Int]) { (n, [n, ..ns]) } }
  }

  fn pop() -> State[ArrayView[Int], Int] {
    {
      runState: fn(ns : ArrayView[Int]) {
        match ns {
          [] => abort("empty stack")
          [n, .. ns] => (n, ns)
        }
      },
    }
  }

  fn plus() -> State[ArrayView[Int], Int] {
    pop().bind(fn(n1) { pop().bind(fn(n2) { push(n1 + n2) }) })
  }

  fn mult() -> State[ArrayView[Int], Int] {
    pop().bind(fn(n1) { pop().bind(fn(n2) { push(n1 * n2) }) })
  }

  let prog : State[ArrayView[Int], Int] = push(2)
    .bind(fn(_) { push(3) })
    .bind(fn(_) { push(5) })
    .bind(fn(_) { plus() })
    .bind(fn(_) { mult() })
  assert_eq(prog.run_state([]), (16, [16]))
  let prog2 : State[ArrayView[Int], String] = State::new(10)
    .bind(fn(x) { push(3 + x) })
    .bind(fn(_) { push(5) })
    .bind(fn(_) { mult() })
    .map(fn(x) { x.to_string() })
  assert_eq(prog2.eval_state([]), "65")
  let prog3 = push(2).bind(fn(_) { push(3) }).bind(fn(_) { get() })
  assert_eq(prog3.eval_state([]), [3, 2])
  let prog4 = State::new(0).bind(fn(_) { put(123) }).bind(fn(_) { get() })
  assert_eq(prog4.run_state(0), (123, 123))
  let prog5 : State[ArrayView[Int], Int] = State::new(5)
  assert_eq(prog5.eval_state([]), 5)
  let prog6 : State[ArrayView[Int], Int] = push(2)
    .bind(fn(_) { modify(fn(x) { [100, ..x] }) })
    .bind(fn(_) { mult() })
  assert_eq(prog6.run_state([]), (200, [200]))
}

///|
test "tick_state" {
  fn tick() -> State[Int, Int] {
    get().bind(fn(x) { put(x + 1).bind(fn(_) { State::new(x) }) })
  }

  for i = 0; i < 100; i = i + 1 {
    assert_eq(tick().exec_state(i), i + 1)
  }
}
