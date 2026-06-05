import 'package:museflow/features/manuscript/domain/manuscript.dart';

/// Sort modes for the manuscript library view.
///
/// D-08: Library supports multiple sort options: recent edit (default),
/// creation date, title alphabetical.
enum ManuscriptSortMode {
  recentEdit,
  creationDate,
  titleAlphabetical,
}

/// Compares two manuscripts according to the given [mode].
///
/// Returns a negative value if [a] should come before [b],
/// a positive value if [a] should come after [b],
/// or zero if they are equal in the given sort dimension.
int compareManuscripts(Manuscript a, Manuscript b, ManuscriptSortMode mode) {
  return switch (mode) {
    ManuscriptSortMode.recentEdit => b.updatedAt.compareTo(a.updatedAt),
    ManuscriptSortMode.creationDate => b.createdAt.compareTo(a.createdAt),
    ManuscriptSortMode.titleAlphabetical => a.title.compareTo(b.title),
  };
}
