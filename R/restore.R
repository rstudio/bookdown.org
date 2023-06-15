## This file is useful to manually restore some file during PR review of GHA auto update 
## TODO: update automatic rules to fix the issue

files <- fs::dir_ls("content/archive/internal/", glob = "*.md")

res <- purrr::map_lgl(files, ~ grepl("R course at Ewha Womans University.", brio::read_file(.x)))
res
files[res]
fs::file_delete(setdiff(files[res], "content/archive/internal/sunboklee-ewha-r.md"))
gert::git_add("content/archive/internal")
gert::git_commit("Remove Ehwa course book")
gert::git_push()

files <- fs::dir_ls("content/archive/internal/", glob = "*.md")
res <- purrr::map_lgl(files, ~ grepl("SWBio Bioinformatics course", brio::read_file(.x)))
res
files[res]


# restore some file
gert::git_branch_checkout("main")
gert::git_pull("upstream", refspec = "main")
gert::git_branch_checkout("updates/gha-auto")

git_restore <- function(file) {
  sys::exec_wait("git", c("checkout", "main", "--", file))
}

git_restore("content/archive/internal/ajkurz-recoding-hayes-2018.md")
git_restore("content/archive/internal/ajsage-statistics-for-data-science-r-code-guide.md")
git_restore("content/archive/internal/frederick-peck-textbook.md")
git_restore("content/archive/internal/jkylearmstrong-fundamentals-of-data-wrangling.md")
# git_restore("content/archive/internal/tpinto-home-unsupervised-learning.md")
# git_restore("content/archive/internal/alhdzsz-data-viz-ir.md")
git_restore("content/archive/internal/daniel-flores-agreda-prob1-gsem-unige.md")
# git_restore("content/archive/internal/hhwagner1-landgencourse-book.md")
git_restore("content/archive/internal/shemanefer-esna2.md")
git_restore("content/archive/internal/baba-yoshihiko-doing-meta-analysis-in-r.md")
git_restore("content/archive/internal/tpinto-home-regularisation.md")

gert::git_add("content/archive/internal")
gert::git_commit("Restore some files")
gert::git_pull(rebase = TRUE)
gert::git_push()
