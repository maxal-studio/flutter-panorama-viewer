/// Defines the state of the selection process
enum SelectionState {
  /// No selection is being drawn
  idle,

  /// A selection is currently being drawn
  drawing,

  /// A selection has been completed
  completed,
}
