fn left_identity[S, V](
  x : V,
  f : (V) -> State[S, V]
) -> (State[S, V], State[S, V]) {
  (State::new(x).bind(f), f(x))
}

fn right_identity[S, V](m : State[S, V]) -> (State[S, V], State[S, V]) {
  (m, m.bind(State::new))
}

fn bind_associator[S, V, W, X](
  m : State[S, V],
  f : (V) -> State[S, W],
  g : (W) -> State[S, X]
) -> (State[S, X], State[S, X]) {
  (m.bind(f).bind(g), m.bind(fn { x => f(x).bind(g) }))
}

fn run_state_eq[S : Eq + Show, V : Eq + Show](
  m : (State[S, V], State[S, V]),
  state : S
) -> Bool {
  let (v1, s1) = run_state(m.0, state)
  let (v2, s2) = run_state(m.1, state)
  v1 == v2 && s1 == s2
}

test "state_monad_laws" {
  let counter = State::new(10)
  fn add(s) -> State[Int, Int] {
    put(s + 2).bind(fn { _ => get() })
  }

  fn mul(s) -> State[Int, Int] {
    put(s * 2).bind(fn { _ => get() })
  }

  let m1 = left_identity(10, add)
  assert_true!(run_state_eq(m1, 0))
  let m2 = right_identity(counter)
  assert_true!(run_state_eq(m2, 0))
  let m3 = bind_associator(counter, add, mul)
  assert_true!(run_state_eq(m3, 0))
}

fn map_identity[S, V](m : State[S, V]) -> State[S, V] {
  m.map(fn { x => x })
}

fn map_associator[S, V, W, X](
  m : State[S, V],
  f : (V) -> W,
  g : (W) -> X
) -> (State[S, X], State[S, X]) {
  (m.map(f).map(g), m.map(fn { x => g(f(x)) }))
}

test "state_functor_laws" {
  let counter = State::new(10)
  let add = fn { x => x + 2 }
  let mul = fn { x => x * 2 }
  let m1 = map_identity(counter)
  assert_true!(run_state_eq((counter, m1), 0))
  let m2 = map_associator(counter, add, mul)
  assert_true!(run_state_eq(m2, 0))
}
