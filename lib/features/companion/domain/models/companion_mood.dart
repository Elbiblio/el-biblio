/// Mood state drives the companion orb's breathing rate, glow strength,
/// and subtle motion. Single source of truth; ties to chat-session state.
enum CompanionMood {
  idle,       // resting, slow breath
  attentive,  // user is composing; leaning in
  thinking,   // awaiting first assistant token
  speaking,   // assistant text streaming in
  warm,       // welcome / celebration moment
  recalling,  // pulling from memory / tool use
}
