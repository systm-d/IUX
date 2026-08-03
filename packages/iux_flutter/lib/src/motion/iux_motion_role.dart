/// What an animation is for.
///
/// A component names the role; the policy decides duration, easing and whether
/// it runs at all. Naming the intent rather than the timing is what lets a
/// reduced-motion preference be applied once, correctly, instead of being
/// re-decided in every component.
///
/// If a movement matches no role here, it is almost certainly decoration.
enum IuxMotionRole {
  /// A value changed in place: a count, a colour, a selected state.
  ///
  /// Answers "what just changed". Shortened when less motion is requested;
  /// the change itself remains visible.
  stateChange,

  /// Something appeared.
  ///
  /// Answers "where did this come from". Shortened, never turned into a jump
  /// that leaves the user hunting for what is new.
  enter,

  /// Something left.
  ///
  /// Answers "where did it go", which is what prevents the user wondering
  /// whether they lost it.
  exit,

  /// Content expanded into view, such as an accordion opening.
  ///
  /// Simplified under reduced motion: the size change becomes a fade, because
  /// it is the growth that is uncomfortable, not the appearance.
  reveal,

  /// Content collapsed out of view.
  conceal,

  /// An element moved from one place to another.
  ///
  /// The role most likely to cause discomfort: large travel across the screen
  /// is a known vestibular trigger. Simplified to a fade under reduced motion
  /// rather than shortened, because a fast large movement is worse than a slow
  /// one, not better.
  reposition,

  /// An operation is ongoing.
  ///
  /// Preserved wherever possible: removing it hides the fact that work is
  /// happening, which is worse than the motion. When motion is fully disabled
  /// the component must substitute a static indicator — a percentage, a count,
  /// a status line.
  progress,

  /// Movement drawing attention to something that did not change.
  ///
  /// Decoration. Removed as soon as the user asks for less, and worth
  /// questioning even when they have not: if an element needs to move to be
  /// noticed, its placement or wording is usually the real problem.
  emphasis,
}

/// What happens to an animation when the user asks for less motion.
enum IuxReducedMotionBehavior {
  /// Runs unchanged. Reserved for roles whose absence would hide information.
  preserve,

  /// Runs, with a shorter duration and simpler easing.
  shorten,

  /// Runs, but as a fade rather than as travel or a size change.
  ///
  /// Keeps the transition legible while removing the movement itself.
  simplify,

  /// Does not run. The state change is instant.
  remove,
}

/// How each role behaves, and why.
extension IuxMotionRoleBehaviour on IuxMotionRole {
  /// Whether this role carries information.
  ///
  /// A decorative role is removed as soon as any reduction is requested; an
  /// essential one is adapted instead.
  bool get isEssential => this != IuxMotionRole.emphasis;

  /// What happens to this role under [IuxMotionPreference.reduced].
  IuxReducedMotionBehavior get reducedBehavior => switch (this) {
        IuxMotionRole.stateChange => IuxReducedMotionBehavior.shorten,
        IuxMotionRole.enter => IuxReducedMotionBehavior.shorten,
        IuxMotionRole.exit => IuxReducedMotionBehavior.shorten,
        IuxMotionRole.reveal => IuxReducedMotionBehavior.simplify,
        IuxMotionRole.conceal => IuxReducedMotionBehavior.simplify,
        IuxMotionRole.reposition => IuxReducedMotionBehavior.simplify,
        IuxMotionRole.progress => IuxReducedMotionBehavior.preserve,
        IuxMotionRole.emphasis => IuxReducedMotionBehavior.remove,
      };
}
