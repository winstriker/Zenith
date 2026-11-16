/// Hero tags shared by FABs across pages.
///
/// FABs with the same tag on two routes morph into each other during the
/// page transition, so every page uses these for its matching buttons.
/// A route must not show two FABs with the same tag at once.
library;

/// The main bottom-right action of a page: "Add" on lists, "Edit" on details,
/// "Save" on forms.
const primaryFabHeroTag = 'primaryFab';

/// The small "more" button above the primary one, opening a speed dial.
const moreFabHeroTag = 'moreFab';

/// The top-left close button.
const closeFabHeroTag = 'closeFab';
