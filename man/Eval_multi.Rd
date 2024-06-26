% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.R
\name{Eval_multi}
\alias{Eval_multi}
\title{Evaluate estimation methods}
\usage{
Eval_multi(
  prop.real,
  prop.est,
  method.name = NULL,
  by.subject = FALSE,
  select.ct = NULL,
  ...
)
}
\arguments{
\item{prop.real}{a matrix of real cell type proportions}

\item{prop.est}{a matrix or a list of matrices of estimated cell type proportions}

\item{method.name}{vector of the names of estmation methods. Default is NULL and the names will be
generated automatically as 'Est1', 'Est2', ...}

\item{by.subject}{logical, default is FALSE. If TRUE, Pearson correlation is estimated subject by subject.}

\item{select.ct}{a vector of cell types selected for evaluation. Default is NULL. If select.ct is NULL, we evaluate
real and estimated cell type proportion with all common cell types. Otherwise use only selected cell types.}
}
\value{
a matrix of evaluation
}
\description{
Calculate Pearson correlation, RMSE and mAD between real and estimated cell type proportions
}
