setwd(blogdown:::site_root())
xfun::in_dir('.', sys.source('R/create-md.R', environment()))

if ('yihui' %in% rsconnect::accounts('bookdown.org')[['name']]) {
  blogdown::hugo_build()
  rsconnect::deploySite('.', 'homepage', 'yihui', 'bookdown.org')
}
