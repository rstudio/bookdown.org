## This file is useful to manually restore some file during PR review of GHA auto update
## TODO: update automatic rules to fix the issue

# main should be up to date
gert::git_branch_checkout("main")
gert::git_pull("upstream", refspec = "main", rebase = TRUE)
gert::git_branch_checkout("updates/gha-auto")

files <- fs::dir_ls("content/archive/internal/", glob = "*.md")

res <- purrr::map_lgl(files, ~ grepl("R course at Ewha Womans University.", brio::read_file(.x)))
res
files[res]
fs::file_delete(setdiff(files[res], "content/archive/internal/sunboklee-ewha-r.md"))
added <- gert::git_add("content/archive/internal")
if (any(added$staged)) gert::git_commit("Remove Ehwa course book")
gert::git_push()

files <- fs::dir_ls("content/archive/internal/", glob = "*.md")
res <- purrr::map_lgl(files, ~ grepl("SWBio Bioinformatics course", brio::read_file(.x)))
res
files[res]


# restore some file
git_restore <- function(file) {
  if (file.exists(file)) return()
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
git_restore("content/archive/internal/daniel-dauber-io-r4np-book.md")
git_restore("content/archive/internal/paul-shiny-workshop.md")
git_restore("content/archive/internal/sbtseiji-jamovi-complete-guide.md")
git_restore("content/archive/internal/andrew-grant-regularisation.md")
git_restore("content/archive/internal/kevin-davisross-gsb518-handouts-2022.md") # quarto book
git_restore("content/archive/internal/maria-gallegos-where-are-genes-2023.md")
git_restore("content/archive/internal/martin-shepperd-moderndatabook.md")
git_restore("content/archive/internal/mathiasharrer-doing-meta-analysis-in-r.md")
git_restore("content/archive/internal/marktrede-ds2inferenz.md")
git_restore("content/archive/internal/kim-intro-to-r.md")
git_restore("content/archive/internal/smartai4ir-dui-ai-solution.md")
git_restore("content/archive/internal/sengokucolaingoo-cbook.md")
git_restore("content/archive/internal/hefleyt2-stat764fall2020.md")
git_restore("content/archive/internal/lisakmnsk-lmu-fintech-financial-data-science.md")
git_restore("content/archive/internal/ggiaever-r4ds-ggplot2.md")
git_restore("content/archive/internal/ggiaever-2024-rna-seq-analysis.md")
git_restore("content/archive/internal/dsciencelabs-alin-tambang.md")
git_restore("content/archive/internal/blazej-kochanski-statystyka2.md")

added <- gert::git_add("content/archive/internal")
if (any(added$staged)) gert::git_commit("Restore some files")

# Remove content that are identified as wrongful

delete_if_exists <- function(file) {
  if (!file.exists(file)) return()
  fs::file_delete(file)
}

# CRC press unauthorized translation
delete_if_exists("content/archive/internal/wangzhen-jmr.md")
delete_if_exists("content/archive/internal/wangzhen-survival.md")
delete_if_exists("content/archive/internal/wangzhen-glmm.md")
delete_if_exists("content/archive/internal/wangzhen-amd.md")
delete_if_exists("content/archive/internal/wangzhen-glm.md")

added <- gert::git_add("content/archive/internal")
if (any(added$staged)) gert::git_commit("Remove content that is not following rules")

gert::git_pull(rebase = TRUE)
gert::git_push()
