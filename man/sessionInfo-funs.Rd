% Generated by roxygen2 (4.0.0): do not edit by hand
\name{sessionRepo}
\alias{getSessionPackages}
\alias{sessionRepo}
\title{Create a virtual repository with the exact package versions recorded by sessionInfo

This function creates a *virtual* repository containing only the exact packages specified by a sessionInfo.

Packages are located via the \code{getSessionPackages} function, which will look in the following places:
\enumerate{
\item{The \code{repo} repository or associated notrack directory}
\item{The current CRAN repository}
\item{The CRAN archives of previous source packages}
\item{The current Bioconductor repository}
\item{The Bioconductor SVN history}
\item{The SCM (SVN/git) history for a GRAN package}
}

When found, package versions not already in the GRAN repository proper or notrack directory are built into the \code{repo}'s associated notrack directory.

The repository is the constructed as a sibling to \code{repo}'s repository using only symbolic links. This allows many virtual repositories to contain the same versions of packages without physical file duplication.}
\usage{
sessionRepo(sinfo = sessionInfo(), repo_dir, doi = NULL, dir, name = NULL,
  replace = FALSE, stoponfail = TRUE, GRepo = GRANRepo, install = FALSE,
  libloc = NULL)

getSessionPackages(sinfo, dir, repo = NULL, stoponfail = FALSE)
}
\arguments{
\item{sinfo}{A sessionInfo object or character containing the text from printing a sessionInfo}

\item{repo_dir}{The base directory to create the virtual repository under}

\item{doi}{A DOI associated with the session info. Currently ignored.}

\item{name}{The name of the repository to create. Defaults to a 32 character hash generated from \code{sinfo}}

\item{replace}{logical. Indicates whether the newly created virtual repository should overwrite any exists virtual repositories of the same name}

\item{stoponfail}{logical. Indicates whether the function should throw an error if it is unable to retreive one or more of the specified package versions. Defaults to \code{TRUE}}

\item{GRepo}{(optional) a \code{GRANRepository} to act as a parent to the
virtual repository}

\item{install}{should the packages be immediately installed into
\code{libloc}. Defaults to FALSE}

\item{libloc}{If packages are being installed, a library location to
contain only the packages for this session info. In generally this should
not be your standard library.}

\item{repo}{(optional) GRANRepository object to search}

\item{dir}{The directory to download/build the package tarballs in}
}
\value{
for \code{sessionRepo} the path to the created virtual repository

for \code{getSessionPackages}, a character vector with the full path to each downloaded/built tar.gz file.
}
\description{
sessionRepo
}
\details{
Create a virtual repository which contains only the exact packages used in
a previous session.
}
\author{
Gabriel Becker
}

