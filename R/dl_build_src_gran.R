#' download and build packages w/ deps
#' 
#' Download and build GRAN packages w/ GRAN and CRAN deps
#' 
#' @param GRAN.dir local directory for GRAN built packages
#' 
#' @import httr devtools
#' @export
dl_build_src <- function(GRAN.dir = './GRAN'){
	repos=c(CRAN="https://cran.rstudio.com/", USGS='http://owi.usgs.gov/R')
	
	
	################################################################################
	## These options may need to be edited for your local system
	## we try to infer the rest
	################################################################################
	src_dir = file.path(GRAN.dir, 'src', 'contrib')
	################################################################################
	## /options
	################################################################################
	
	##Update all the local packages so we're always working with the latest
	update.packages(ask=FALSE, lib.loc = Sys.getenv('R_LIBS_USER'), repos=repos)
	
	packages = read_src_list()
	
	unlink(file.path(GRAN.dir, 'src'), recursive=TRUE)
	dir.create(src_dir, recursive = TRUE)
	scratch = tempdir()
	
	for(i in 1:nrow(packages)){
		
		url = paste0('http://github.com/', packages$package[i], '/archive/', packages$tag[i], '.zip')
		
		GET(url, write_disk(file.path(scratch, 'package.zip'), overwrite=TRUE))
		
		unzip(file.path(scratch, 'package.zip'), exdir=file.path(scratch, packages$package[i]))
		
		pkgdirname = Sys.glob(paste0(scratch, '/', packages$package[i], '/', basename(packages$package[i]), '*'))
		
		devtools::install_deps(pkgdirname,type = 'both')
		
		if(length(pkgdirname) > 1){
			stop('too many files in downloaded zip, ambiguous build info')
		}
		
		cmd = paste0('R CMD build ', pkgdirname, ' --no-build-vignettes --no-manual')
		system(cmd)
		write_PACKAGES(getwd(), type='source')
		gran_packages = data.frame(available.packages(paste0('file:', getwd()), type='source'))
		
		built_pkg = Sys.glob(paste0(gran_packages$Package,"_",gran_packages$Version,".tar.gz"))
		
		issuccess = file.rename(built_pkg, file.path(src_dir, basename(built_pkg)))
		
		if(!issuccess){
			stop('Cannot move package', packages$package[i], 'to local GRAN area')
		}
	}
	
	write_PACKAGES(src_dir, type='source')
}



