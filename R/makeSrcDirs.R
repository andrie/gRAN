#manifest is a data.frame with fourth columns: name, (repo) url, type, branch
makeSrcDirs = function(repo, cores = 3L, scm_auth)
{
    binds = getBuilding(repo = repo)
    
    manifest = getBuildingManifest(repo = repo)
    scm_auth = replicate(scm_auth, n=nrow(manifest), simplify=FALSE)
    sources = mapply(makeSource, url = manifest$url, type = manifest$type, scm_auth= scm_auth)
    path = repo@tempCheckout
    res <- mcmapply(function(nm, src, branch, subdir, repo, path)  makePkgSourceDir(name = nm, source = src, path =path, branch = branch, repo=repo),
                    nm = manifest$name,
                    branch = manifest$branch,
                    subdir = manifest$subdir,
                    src = sources,
                    path = path,
                    repo = list(repo),
                    mc.cores = cores)
    res = unlist(res)
    if(!is.logical(res)) 
        print(res)
    ##repo@manifest[binds, "building"] = res
    repo@manifest$status[binds][!res] = "source checkout failed"
    repo
}

