if (identical(commandArgs(TRUE), 'FALSE'))
  xfun::in_dir(blogdown:::site_root(), sys.source('R/create-md.R', environment()))
