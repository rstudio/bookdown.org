xfun::in_dir('R', sys.source('create-md.R', environment()))

if ('yihui' %in% rsconnect::accounts('bookdown.org')[['name']]) {
  blogdown::hugo_build()
  rsconnect::deploySite('.', 'homepage', 'yihui', 'bookdown.org')
}
