import 'github_gists_source.dart';
import 'gitlab_snippets_source.dart';
import 'glot_source.dart';
import 'paste_source.dart';
import 'pastebin_archive_source.dart';

/// Builds the default set of sources the scanner knows about.
List<PasteSource> defaultSources() => [
      GithubGistsSource(),
      GitlabSnippetsSource(),
      GlotSource(),
      PastebinArchiveSource(),
    ];
