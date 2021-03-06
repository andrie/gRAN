setMethod("makePkgSourceDir", c(name = "ANY", source = "SVNSource"), function(name, source, path, branch = "master", subdir = "./", repo) {
    oldwd = getwd()
    on.exit(setwd(oldwd))
    if(!file.exists(path))
        dir.create(path, recursive = TRUE)
    setwd(path)
    
    if(missing(name))
        name = basename(location(source))
    
    opts = character()
    if(length(source@user) && nchar(source@user))
        opts = paste(opts, "--username", source@user)
    if(length(source@password) && nchar(source@password))
        opts = paste(opts, "--password", source@password)
    
    #did we already check it out?
    if(file.exists(name))
    {
        writeGRANLog(name, "Existing temporary checkout found at this location. Updating", repo =  repo)
        up = updateSVN(file.path(path, name), source, repo)
        #if(!up)
        #    return(FALSE)
    } else {

        cmd = paste("svn co", location(source), name, opts)
        writeGRANLog(name, paste0("Attempting to create temporary source directory from SVN repo ", location(source), " (branch ", branch, "; cmd ", cmd, " )"), repo = repo)        
        out = tryCatch(system_w_init(cmd, repo = repo), error = function(x) x)
        if(is(out, "error"))
        {
            msg = c(paste("Temporary SVN checkout failed. cmd:", cmd), out$message)
            writeGRANLog(name, msg, type="error", repo = repo)
            return(FALSE)
        }
    }
    rtdir = file.path(path, name)

    ret = !is.null(findPkgDir(rtdir, branch, subdir, repo = repo))

    
    #success log
    if(ret)
    {
        writeGRANLog(name, paste("Temporary source directory successfully created:", ret), repo = repo)
        
            
    }
    ret
})

setMethod("makePkgSourceDir", c(name = "ANY", source = "GitSVNSource"), function(name, source, path, branch = "master", subdir = "./", repo) {
    oldwd = getwd()
    on.exit(setwd(oldwd))
    if(!file.exists(path))
        dir.create(path, recursive = TRUE)
    setwd(path)
    
    if(missing(name))
        name = basename(location(source))
    
    opts = character()
    pword = character()
    if(length(source@user) && nchar(source@user))
        opts = paste(opts, "--username", source@user)
    if(length(source@password) && nchar(source@password))
        pword = paste("echo", source@password, " | ")
    #did we already check it out?
    if(file.exists(name))
    {
        writeGRANLog(name, "Existing temporary checkout found at this location. Updating", repo =  repo)
        up = updateSVN(file.path(path, name), source, repo)
        #if(!up)
        #    return(FALSE)
    } else {
        writeGRANLog(name, paste0("Attempting to create temporary source directory from SVN repo ", location(source), " (branch", branch, ")"), repo = repo)
        cmd = paste(pword, "git svn clone", location(source), name, opts)
        
        out = tryCatch(system_w_init(cmd, repo = repo), error = function(x) x)
        if(is(out, "error"))
        {
            msg = c(paste("Temporary git SVN checkout failed. cmd:", cmd), out$message)
            writeGRANLog(name, msg, type="error", repo = repo)
            return(FALSE)
        }
    }
    rtdir = file.path(path, name)

    ret = !is.null(findPkgDir(rtdir, branch, subdir, repo = repo))

    
    #success log
    if(ret)
    {
        writeGRANLog(name, paste("Temporary source directory successfully created:", ret), repo = repo)
        
            
    }
    ret
})


setMethod("makePkgSourceDir", c(name = "ANY", source = "GitSource"), function(name, source, path, branch, subdir, repo) {
    oldwd = getwd()
    on.exit(setwd(oldwd))
    if(!file.exists(path))
        dir.create(path, recursive = TRUE)
    setwd(path)
    sdir = location(source)
    if(missing(branch) || is.na(branch))
        branch = "master"

    if(file.exists(name)) {
        writeGRANLog(name, "Existing temporary checkout found at this location. Updating", repo =  repo)
        up = updateGit(file.path(path, name), source, repo, branch = branch)
        #if(!up)
        #    return(FALSE)
    } else {
        cmd = paste("git clone", sdir, name, ";cd", name, "; git checkout", branch)
        res = tryCatch(system_w_init(cmd, intern=TRUE, repo = repo),
            error=function(x) x)
        if(is(res, "error") || (!is.null(attr(res, "status")) && attr(res, "status") > 0))
        {
            writeGRANLog(name, paste("Failed to check out package source using command:", cmd), type="both", repo = repo)
            writeGRANLog(name, res, type="error", repo = repo)
            return(FALSE)
        }
        
        writeGRANLog(name, paste0("Successfully checked out package source from ", sdir, " on branch ", branch), repo = repo)
    }
    rtdir = file.path(path, name)
    
    ret = !is.null(findPkgDir(rtdir, branch, subdir, repo=repo))
    #success log
    if(ret)
    {
        writeGRANLog(name, paste("Temporary source directory successfully created:", ret), repo = repo)
    }
    ret
})
                                        #stub for everyone else
setMethod("makePkgSourceDir", c(name = "ANY", source = "ANY"), function(name, source, path, branch, subdir, repo) {
    warning("Source type not supported yet.")
    FALSE
})

setMethod("makePkgSourceDir", c(source="LocalSource"), function(name, source, path, branch, subdir ="./", repo) {
    oldwd = getwd()
    on.exit(setwd(oldwd))
    if(!file.exists(path))
        dir.create(path, recursive = TRUE)
    setwd(path)
    
    if(missing(name))
        name = basename(location(source))
    
    writeGRANLog(name, "Copying local source directory into temporary checkout directory.", repo = repo)
    
   # ok= file.copy(location(source), file.path(path, name), recursive = TRUE)
    ok = file.copy(normalizePath2(location(source)), file.path(path), recursive=TRUE)
    if(basename(location(source)) != name)
    {
        writeGRANLog(name, "Renamed copied directory to package name.", repo = repo)
        ok = file.rename(file.path(path, basename(location(source))), file.path(path, name))
    }
    ret = normalizePath2(file.path(path, name, subdir))
    
                                        #success log
    if(ok)
    {
        writeGRANLog(name, paste("Temporary source directory successfully created:", ret), repo = repo)
    }
    ok
    
})
