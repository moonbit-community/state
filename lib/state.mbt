/// A simple implementation of the State Monad.
struct State[S, V] {
  runState : (S) -> (V, S)
}

/// Create a new state monad with a value.
/// 
/// # Example
/// ```
/// let state: State[List[Int], Int] = State::new(10)
/// ```
pub fn State::new[S, V](val : V) -> State[S, V] {
  { runState: fn { state => (val, state) } }
}

/// Embed a simple state action into the state monad.
/// 
/// # Example
/// ```
/// let state: State[Int, Int] = state(fn { x => (x + 1, x + 1) })
/// ```
pub fn state[S, V](f : (S) -> (V, S)) -> State[S, V] {
  { runState: f }
}

/// Return the state from the internals of the monad.
/// 
/// # Example
/// ```
/// let state: State[Int, Int] = State::new(10)
///   |> bind(fn { _ => get() })
/// ```
pub fn get[S]() -> State[S, S] {
  { runState: fn { state => (state, state) } }
}

/// Replace the state inside the monad.
/// 
/// # Example
/// ```
/// let state: State[Int, Unit] = State::new(10)
///  |> bind(fn { _ => put(20) })
/// ```
pub fn put[S](new_state : S) -> State[S, Unit] {
  { runState: fn { _ => ((), new_state) } }
}

/// Maps a value inside a state monad.
/// 
/// # Example
/// ```
/// let state : State[Int, Int] = State::new(10)
///   |> map(fn { x => x + 1 })
/// ```
pub fn map[S, V, W](self : State[S, V], f : (V) -> W) -> State[S, W] {
  {
    runState: fn(state : S) {
      let (val, new_state) = (self.runState)(state)
      (f(val), new_state)
    },
  }
}

/// Maps an old state to a new state inside a state monad.
/// 
/// # Example
/// ```
/// let state : State[Int, Int] = State::new(0)
///  |> bind(fn { _ => modify(fn { x => x + 1 }) })
///  |> bind(fn {_  => get()})
/// ```
pub fn modify[S](f : (S) -> S) -> State[S, Unit] {
  { runState: fn(state : S) { ((), f(state)) } }
}

/// Bind a state monad computation to a function.
/// 
/// # Example
/// ```
/// let state : State[Int, Int] = State::new(10)
///  |> bind(fn { _ => put(20) })
///  |> bind(fn { _ => get() |> bind(fn { x => new(x + 1) }) })
/// ```
pub fn bind[S, V, W](self : State[S, V], f : (V) -> State[S, W]) -> State[S, W] {
  {
    runState: fn(state : S) {
      let (val, new_state) = (self.runState)(state)
      let { runState: g } = f(val)
      g(new_state)
    },
  }
}

/// Unwrap a state monad computation as a function.
/// 
/// # Example
/// ```
/// let state : State[Int, Int] = State::new(10)
/// run_state(state, 0)
/// ```
pub fn run_state[S, V](self : State[S, V], state : S) -> (V, S) {
  (self.runState)(state)
}

/// Evaluate a state computation with the given initial state and return the final value, discarding the final state.
/// 
/// # Example
pub fn eval_state[S, V](self : State[S, V], state : S) -> V {
  run_state(self, state).0
}

/// Evaluate a state computation with the given initial state and return the final state, discarding the final value.
/// 
/// # Example
/// ```
/// let state : State[Int, Unit] = State::new(10)
///  |> bind(fn { _ => put(20) })
/// ```
pub fn exec_state[S, V](self : State[S, V], state : S) -> S {
  run_state(self, state).1
}