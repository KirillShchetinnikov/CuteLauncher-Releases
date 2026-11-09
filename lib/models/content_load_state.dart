/// Metadata readiness, independent of poster decoding and Home readiness.
enum ContentLoadState { initial, ready, refreshing, empty, error }

ContentLoadState contentLoadState({
  required bool initialized,
  required bool loading,
  required bool failed,
  required bool hasContent,
}) {
  if (!initialized) return ContentLoadState.initial;
  if (loading) return ContentLoadState.refreshing;
  if (failed) return ContentLoadState.error;
  return hasContent ? ContentLoadState.ready : ContentLoadState.empty;
}
