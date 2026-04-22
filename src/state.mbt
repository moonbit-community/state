///|
/// A simple implementation of the State Monad.
struct State[S, V] {
  runState : (S) -> (V, S)
}

///|
/// Create a new state monad with a value.
/// 
/// # Example
/// ```
/// let _state: State[Int, Int] = State::new(10)
/// ```
pub fn[S, V] State::new(val : V) -> State[S, V] {
  { runState: fn(state) { (val, state) } }
}

///|
/// Embed a simple state action into the state monad.
/// 
/// # Example
/// ```
/// let _state: State[Int, Int] = state(fn(x) { (x + 1, x + 1) })
/// ```
pub fn[S, V] state(f : (S) -> (V, S)) -> State[S, V] {
  { runState: f }
}

///|
/// Return the state from the internals of the monad.
/// 
/// # Example
/// ```
/// let _state: State[Int, Int] = State::new(10).bind(fn(_) { get() })
/// ```
pub fn[S] get() -> State[S, S] {
  { runState: fn(state) { (state, state) } }
}

///|
/// Replace the state inside the monad.
/// 
/// # Example
/// ```
/// let _state: State[Int, Unit] = State::new(10).bind(fn(_) { put(20) })
/// ```
pub fn[S] put(new_state : S) -> State[S, Unit] {
  { runState: fn(_) { ((), new_state) } }
}

///|
/// Maps a value inside a state monad.
/// 
/// # Example
/// ```
/// let _state : State[Int, Int] = State::new(10).map(fn(x) { x + 1 })
/// ```
pub fn[S, V, W] State::map(self : State[S, V], f : (V) -> W) -> State[S, W] {
  {
    runState: fn(state : S) {
      let (val, new_state) = (self.runState)(state)
      (f(val), new_state)
    },
  }
}

///|
/// Maps an old state to a new state inside a state monad.
/// 
/// # Example
/// ```
/// let _state : State[Int, Int] = State::new(0)
///   .bind(fn(_) { modify(fn(x) { x + 1 }) })
///   .bind(fn(_) { get() })
/// ```
pub fn[S] modify(f : (S) -> S) -> State[S, Unit] {
  { runState: fn(state : S) { ((), f(state)) } }
}

///|
/// Bind a state monad computation to a function.
/// 
/// # Example
/// ```
/// let _state : State[Int, Int] = State::new(10)
///   .bind(fn(_) { put(20) })
///   .bind(fn(_) { get().bind(fn(x) { State::new(x + 1) }) })
/// ```
pub fn[S, V, W] State::bind(
  self : State[S, V],
  f : (V) -> State[S, W],
) -> State[S, W] {
  {
    runState: fn(state : S) {
      let (val, new_state) = (self.runState)(state)
      let { runState: g } = f(val)
      g(new_state)
    },
  }
}

///|
/// Unwrap a state monad computation as a function.
/// 
/// # Example
/// ```
/// let state : State[Int, Int] = State::new(10)
/// let _result = state.run_state(0)
/// ```
pub fn[S, V] State::run_state(self : State[S, V], state : S) -> (V, S) {
  (self.runState)(state)
}

///|
/// Evaluate a state computation with the given initial state and return the final value, discarding the final state.
/// 
/// # Example
pub fn[S, V] State::eval_state(self : State[S, V], state : S) -> V {
  self.run_state(state).0
}

///|
/// Evaluate a state computation with the given initial state and return the final state, discarding the final value.
/// 
/// # Example
/// ```
/// let _state : State[Int, Unit] = State::new(10).bind(fn(_) { put(20) })
/// ```
pub fn[S, V] State::exec_state(self : State[S, V], state : S) -> S {
  self.run_state(state).1
}
