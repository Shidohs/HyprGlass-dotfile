use crate::apps::AppInfo;
use fuzzy_matcher::skim::SkimMatcherV2;
use fuzzy_matcher::FuzzyMatcher;

pub struct SearchEngine {
    matcher: SkimMatcherV2,
}

impl SearchEngine {
    pub fn new() -> Self {
        Self {
            matcher: SkimMatcherV2::default().smart_case(),
        }
    }

    pub fn filter_indices(&self, apps: &[AppInfo], query: &str) -> Vec<usize> {
        let trimmed = query.trim();
        if trimmed.is_empty() {
            return (0..apps.len()).collect();
        }

        let mut scored_indices: Vec<(usize, i64)> = Vec::with_capacity(apps.len());

        for (idx, app) in apps.iter().enumerate() {
            let mut best_score: Option<i64> = None;

            // 1. Match against application Name (highest boost: +50)
            if let Some(score) = self.matcher.fuzzy_match(&app.name, trimmed) {
                best_score = Some(score + 50);
            }

            // 2. Match against Exec binary name
            let exec_binary = app.exec.split_whitespace().next().unwrap_or("");
            if let Some(score) = self.matcher.fuzzy_match(exec_binary, trimmed) {
                let s = score + 30;
                best_score = Some(best_score.map_or(s, |prev| prev.max(s)));
            }

            // 3. Match against GenericName (e.g. "Web Browser", "Text Editor")
            if let Some(ref gen) = app.generic_name {
                if let Some(score) = self.matcher.fuzzy_match(gen, trimmed) {
                    let s = score + 20;
                    best_score = Some(best_score.map_or(s, |prev| prev.max(s)));
                }
            }

            // 4. Match against Keywords
            for kw in &app.keywords {
                if let Some(score) = self.matcher.fuzzy_match(kw, trimmed) {
                    let s = score + 10;
                    best_score = Some(best_score.map_or(s, |prev| prev.max(s)));
                }
            }

            // 5. Match against Comment / Description
            if let Some(ref comment) = app.comment {
                if let Some(score) = self.matcher.fuzzy_match(comment, trimmed) {
                    best_score = Some(best_score.map_or(score, |prev| prev.max(score)));
                }
            }

            if let Some(score) = best_score {
                scored_indices.push((idx, score));
            }
        }

        // Sort by score descending; if equal score, sort alphabetically
        scored_indices.sort_by(|a, b| {
            b.1.cmp(&a.1).then_with(|| {
                apps[a.0]
                    .name
                    .to_lowercase()
                    .cmp(&apps[b.0].name.to_lowercase())
            })
        });

        scored_indices.into_iter().map(|(idx, _)| idx).collect()
    }
}
