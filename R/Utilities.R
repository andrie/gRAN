checkIsPkgDir = function (dir)
{
    fils = list.files(dir)
    any(grepl("^DESCRIPTION$", fils))
}

writeGRANLog = function(pkg, msg, repo, type = "full")
{
    if(is.null(repo))
        return()
    
    dt = date()
    targs = 
    
    if(type == "error")
    {
        targ = errlogfile(repo)
        err = " ERROR "
    } else if (type == "both") {
        targ = c(logfile(repo), errlogfile(repo))
        err = " ERROR "
    } else {
        targ = logfile(repo)
        err = character()
    }

    
    fullmsg = paste("\n",err, "pkg:", pkg, "(", dt, ") - ",
        paste(paste0("\t",msg), collapse="\n\t"))
    sapply(targ, function(x) cat(fullmsg, append=TRUE, file=x))
}

findPkgDir = function(rootdir, branch, subdir, repo)
{
                   
    ret = NULL
    name = basename(rootdir)
    #does it have the trunk, branches, tags layout?
    if(checkStdSVN(rootdir))
    {
        if(is.null(branch) || branch %in% c("master", "trunk"))
        {
            ret = file.path(rootdir, "trunk")
        } else {
            ret = file.path(rootdir, "branches", branch)
        }
    } else if(is.null(branch) || branch %in% c("master", "trunk")) {
        ret = rootdir
    } else {
        warning(paste0("The svn repository at ", location(source),
                       " does not appear to have branches. ",
                       "Unable to process this source."))
        writeGRANLog(name, paste("The SVN repository does not appear to have",
                                 "branches and a non-trunk/non-master branch",
                                 "was selected"), repo = repo, type="both")
        return(NULL)
    }

    ret = file.path(ret, subdir)
    ##we somehow got a return file that doesn't exist on the file system.
    ##This is a problem with GRAN logic, not with packages/user activity
    if(!file.exists(ret))
    {
        writeGRANLog(name, paste("Unable to find subdirectory", subdir,
                                 "in branch", branch), repo, type="both")
        warning(paste0("Constructed temporary package directory",ret,
                       " doesn't appear to  exist after svn checkout. ",
                       "Missing branch?"))
        return(NULL)
    }
    
    ##Find a package. First look in ret, then in ret/package and ret/pkg
    ##we could be more general and allow people to specify subdirectories...
    if(!checkIsPkgDir(ret))
    {
        writeGRANLog(name, paste("Specified branch/subdirectory combination",
                                 "does not appear to contain an R package"),
                                 repo, type="both")
        ret = NULL
    }
    ret
}

getPkgNames = function(path)
{
    path = normalizePath2(path)
    if(length(path) > 1)
        sapply(path, getPkgNames)
    if(file.info(path)$isdir && file.exists(file.path(path, "DESCRIPTION")))
        read.dcf(file.path(path, "DESCRIPTION"))[1,"Package"]
    else if (grepl(".tar", path, fixed=TRUE))
        gsub(basename(path), "([^_]*)_.*", "\\1")
}


getCheckoutLocs = function(codir, manifest = repo@manifest,
    branch = manifest$branch, repo)
{
    mapply(getPkgDir, basepath = codir, subdir = manifest$subdir,
           scm_type = manifest$type, branch = branch, name = manifest$name)
}

getMaintainers = function(codir, manifest = repo@manifest,
    branch = manifest$branch, repo) {
    sapply(getCheckoutLocs(codir, manifest = manifest), function(x) {
        if(!file.exists(file.path(x,"DESCRIPTION")))
            NA
        else
            read.dcf(file.path(x, "DESCRIPTION"))[,"Maintainer"]
    })
}

makeUserFun = function(scm_auth, url)
    {
        ind = sapply(names(scm_auth), function(pat) grepl(pat, url, fixed=TRUE))
        if(any(ind))
            scm_auth[[which(ind)]][1]
        else
            ""

    }

makePwdFun = function(scm_auth, url)
    {
        ind = sapply(names(scm_auth), function(pat) grepl(pat, url, fixed=TRUE))
        if(any(ind))
            scm_auth[[which(ind)]][2]
        else
            ""
       
    }


makeSource = function(url, type, user, password, scm_auth,...) {
    if(missing(user))
        user = makeUserFun(scm_auth = scm_auth, url = url)
    if(missing(password))
        password = makePwdFun(scm_auth= scm_auth, url = url)
    switch(type,
           svn  = new("SVNSource", location = url, user = user,
               password = password, ...),
           local = new("LocalSource", location = url, user = user,
               password= password, ...),
           git = new("GitSource", location = url, user = user,
               password = password,  ...),
           github = new("GithubSource", location = url, user = user,
               password = password, ...),
           gitsvn = new("GitSVNSource", location = url, user = user,
               password = password, ...),
           stop("unsupported source type")
           )
}

getPkgDir = function(basepath,name,  subdir, scm_type, branch)
{

    basepath = normalizePath2(basepath)
    if(scm_type == "svn")
    {
        if(checkStdSVN(file.path(basepath, name)))
        {
            if(is.na(branch) || branch == "trunk")
                brdir = "trunk"
            else
                brdir = file.path("branches", branch)

        } else {
            brdir = "."

        }
    } else if (scm_type == "git") {
        brdir = "."
    } else if (scm_type == "local") {
        brdir = "."
    } else {
        stop(paste("Unrecognized scm_type in getPkgDir:", scm_type))
    }



    normalizePath2(file.path(basepath,name, brdir, subdir))
}


#system(..., intern=TRUE) throws an error if the the command fails,
#and has attr(out, "status") > 0 if the called program returns non-zero status.
errorOrNonZero = function(out)
{
    if(is(out, "error") ||
       (!is.null(attr(out, "status")) && attr(out, "status") > 0))
        TRUE
    else
        FALSE
}

isOkStatus = function(status= manifest$status, manifest = repo@manifest, repo)
{
    #status can be NA when the package isn't being built at all
    !is.na(status) & (status == "ok" |
                      (repo@checkWarnOk & status == "check warning(s)") |
                      (repo@checkNoteOk & status == "check note(s)"))
}

install.packages2 = function(pkgs, ...)
{
    outdir = tempdir()
    wd = getwd()
    on.exit(setwd(wd))
    setwd(outdir)
    ## the keep_outputs=dir logic doesn't work, the files just
    ##end up in both locations!
    ##install.packages(pkgs, ..., keep_outputs=outdir)
    install.packages(pkgs, ..., keep_outputs=TRUE)
    ret = sapply(pkgs, function(p)
    {
        fil = file.path(outdir, paste0(p, ".out"))
        tmp = readLines(fil)
        outcome = tmp[length(tmp)]
        if(grepl("* DONE", outcome, fixed=TRUE))
            "ok"
        else
            fil
    })
    ret
}


getBuilding = function(repo, manifest = repo@manifest)
{
    manifest$building & isOkStatus(manifest = manifest, repo = repo)
}

getBuildingManifest = function(repo, manifest = repo@manifest)
{
    manifest[getBuilding(repo, manifest),]
}

normalizePath2 = function(path, follow.symlinks=FALSE)
    {
        if(follow.symlinks)
            normalizePath(path)
        else {
            if(substr(path, 1, 1) == "~")
                path = path.expand(path)
            ##paths starting with / for example
            else if(substr(path, 1, 1) == .Platform$file.sep)

                path  = path
            else if (substr(path, 1, 2) == "..") {
                tmppath = getwd()
                while(substr(path, 1, 2) == "..") {
                    tmppath = dirname(tmppath)
                    path = substr(path, 3, nchar(path))
                    if(substr(path, 1, 1) == .Platform$file.sep)
                        path = substr(path, 2, nchar(path))
                }
                path = file.path(tmppath, path)
            } else if(grepl("^\\.*[[:alnum:]]", path))
                path = file.path(getwd(), path)
            else if (substr(path, 1,1) == ".")
                path = file.path(getwd(), substr(path,2, nchar(path)))
            path = gsub(paste(rep(.Platform$file.sep, 2), collapse=""), .Platform$file.sep, path, fixed=TRUE)
            path
            
        }
    }

##source an initialization script (e.g. .bashrc) if specified
## in repo@shell_init
system_w_init = function(cmd, ..., repo = NULL)
{
    if(length(cmd) > 1)
        stop("cmd should be of length 1")
    if(!is.null(repo) && length(repo@shell_init) && nchar(repo@shell_init))
        cmd = paste(paste("source", repo@shell_init), cmd, sep = " ; ")
    system(cmd, ...)
}
