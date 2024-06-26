# Functions for constructions
#
# Author: Xuran Wang

#' Construct artificial bulk tissue expression from single cell data
#'
#' Artificial bulk tissue expression is generated by adding gene expressions of all cells from
#' same subjects.
#'
#' @param sce SingleCellExperiment, single cell dataset
#' @param clusters character, the colData used as clusters
#' @param samples character, the colData used as samples
#' @param select.ct vector of cell types included, default as \code{NULL}. If \code{NULL}, include all cell types in \code{x}.
#' Otherwise, only cells of selected cell types will be used for construction.
#'
#' @return Matrix of expression of constructed bulk tissue, matrix of cell number in each cluster by sample
#' @importFrom Matrix rowSums
#' 
#' @export
bulk_construct = function(sce, clusters, samples, select.ct = NULL){
  if(!is.null(select.ct)){
    sce = sce[, sce@colData[, clusters] %in% select.ct]
  }else{
    select.ct = unique(sce@colData[, clusters])
  }
  mdf = sce@colData
  mdf$index = 1:ncol(sce);
  
  u.sample = as.character(unique(mdf[, samples]))
  bulk.counts = NULL
  bulk.counts = sapply(u.sample, function(x){
    index = mdf$index[mdf[, samples] == x]
    if(length(index) == 1){
      return(counts(sce[, index]))
    }else{
      return(Matrix::rowSums(counts(sce[, index])))
    }
  })
  num.real = t(sapply(u.sample, function(x){
    index = mdf$index[mdf[, samples] == x]
    return(summary(mdf[index, clusters]))
  }))
  num.real = num.real[, select.ct]
  
  return(list(bulk.counts = bulk.counts, num.real = num.real))
}

############ Construct Design Matrix, Library Size, and Subject-level Variation of Relative abundance for MuSiC ############
## These functions are for cell type specific mean expression, cross-subject variance and mean library size for MuSiC deconvolution

#' Cross-subject Mean of Relative Abudance
#'
#' This function is for calculating the cross-subject mean of relative abundance for selected cell types.
#'
#' @param x SingleCellExperiment, single cell dataset
#' @param non.zero logical, if true, remove all gene with zero expression
#' @param markers vector or list of gene names
#' @param clusters character, the phenoData used as clusters
#' @param samples character,the phenoData used as samples
#' @param select.ct vector of cell types included, default as \code{NULL}. If \code{NULL}, include all cell types in \code{x}
#' @return gene by cell type matrix of average relative abundance
#' @importFrom Matrix rowSums
#' 
#' @export
music_M.theta = function(x, non.zero, markers, clusters, samples, select.ct){
  if(!is.null(select.ct)){
    x = x[, x@colData[, clusters] %in% select.ct]
  }
  if(non.zero){  ## eliminate non expressed genes
    x <- x[Matrix::rowSums(counts(x))>0, ]
  }
  
  clusters <- as.character(colData(x)[, clusters])
  samples <- as.character(colData(x)[, samples])
  M.theta <- sapply(unique(clusters), function(ct){
    my.rowMeans(sapply(unique(samples), function(sid){
      y = counts(x)[,clusters %in% ct & samples %in% sid]
      if(is.null(dim(y))){
        return(y/sum(y))
      }else{
        return(rowSums(y)/sum(y))
      }
    }), na.rm = TRUE)
  })
  
  if(!is.null(select.ct)){
    m.ct = match(select.ct, colnames(M.theta))
    M.theta = M.theta[, m.ct]
  }
  
  if (!is.null(markers)){
    ids <- intersect(unlist(markers), rownames(x))
    m.ids = match(ids, rownames(x))
    M.theta <- M.theta[m.ids, ]
  }
  return(M.theta)
}

#' Subject and cell type specific relative abundance
#'
#' This function is for calculating the subject and cell type specific relative abundance for selected cell types.
#'
#' @param x SingleCellExperiment, single cell dataset
#' @param non.zero logical, default as F. If true, remove all gene with zero expression
#' @param markers vector or list of gene names
#' @param clusters character, the colData used as clusters
#' @param samples character,the colData used as samples
#' @param select.ct vector of cell types included, default as \code{NULL}. If \code{NULL}, include all cell types in \code{x}
#' @return gene*subject by cell type matrix of relative abundance
#' @importFrom Matrix rowSums
#'
#' @export
music_Theta <- function(x, non.zero = FALSE, clusters, samples, select.ct = NULL){
  if(!is.null(select.ct)){
    x = x[, x@colData[, clusters] %in% select.ct]
  }
  if(non.zero){
    x <- x[rowSums(counts(x))>0, ]
  }
  nGenes = nrow(x);
  
  clusters <- as.character(pData(x)[, clusters])
  samples <- as.character(pData(x)[, samples])
  Theta <- sapply(unique(clusters), function(ct){
    sapply(unique(samples), function(sid){
      y = counts(x)[,clusters %in% ct & samples %in% sid]
      if(is.null(dim(y))){
        return(y/sum(y))
      }else{
        return(rowSums(y)/sum(y))
      }
    })
  })
  n.ct = length(unique(clusters));
  if(!is.null(select.ct)){
    m.ct = match(select.ct, colnames(Theta))
    Theta = Theta[, m.ct]
    n.ct = length(select.ct)
  }
  
  return(Theta = Theta)
}

#' Cross-subject Covariance of Relative Abundance
#'
#' This function is for calculating the cross-subject covariance of relative abundance for selected cell types.
#'
#' @param x SingleCellExperiment, single cell dataset
#' @param non.zero logical, if true, remove all gene with zero expression
#' @param markers vector or list of gene names
#' @param clusters character, the ColData used as clusters
#' @param samples character,the ColData used as samples
#' @param select.ct vector of cell types included, default as \code{NULL}. If \code{NULL}, include all cell types in \code{x}
#' @return celltype^2 by gene matrix of covariance
#' @importFrom Matrix rowSums
#'
#' @export
music_Sigma.ct = function(x, non.zero, markers, clusters, samples, select.ct){
  if(!is.null(select.ct)){
    x = x[, x@colData[, clusters] %in% select.ct]
  }
  if(non.zero){  ## eliminate non expressed genes
    x <- x[rowSums(counts(x))>0, ]
  }
  nGenes = nrow(x);
  
  clusters <- as.character(colData(x)[, clusters])
  samples <- as.character(colData(x)[, samples])
  Sigma <- sapply(unique(clusters), function(ct){
    sapply(unique(samples), function(sid){
      y = counts(x)[,clusters %in% ct & samples %in% sid]
      if(is.null(dim(y))){
        return(y/sum(y))
      }else{
        return(rowSums(y)/sum(y))
      }
    })
  })
  n.sub = length(unique(samples));
  if(!is.null(select.ct)){
    m.ct = match(select.ct, colnames(Sigma))
    Sigma = Sigma[, m.ct]
    n.ct = length(select.ct)
  }
  Sigma.ct = sapply(1:nGenes, function(g){cov(Sigma[nGenes*(0:(n.sub-1)) + g, ])})
  if (!is.null(markers)){
    ids <- intersect(unlist(markers), rownames(x))
    m.ids = match(ids, rownames(x))
    Sigma.ct <- Sigma.ct[ , m.ids]
  }
  return(Sigma.ct = Sigma.ct)
}

#' Cross-subject Variance of Relative Abundance
#'
#' This function is for calculating the cross-subject variance of relative abundance for selected cell types.
#'
#' @param x SingleCellExperiment, single cell dataset
#' @param non.zero logical, if true, remove all gene with zero expression
#' @param markers vector or list of gene names
#' @param clusters character, the colData used as clusters
#' @param samples character,the colData used as samples
#' @param select.ct vector of cell types included, default as \code{NULL}. If \code{NULL}, include all cell types in \code{x}
#' @return gene by cell type matrix of variance
#' @importFrom Matrix rowSums
#'
#' @export
music_Sigma = function(x, non.zero, markers, clusters, samples, select.ct){
  if(!is.null(select.ct)){
    x = x[, x@colData[, clusters] %in% select.ct]
  }
  if(non.zero){  ## eliminate non expressed genes
    x <- x[rowSums(counts(x))>0, ]
  }
  
  clusters <- as.character(colData(x)[, clusters])
  samples <- as.character(colData(x)[, samples])
  Sigma <- sapply(unique(clusters), function(ct){
    apply(sapply(unique(samples), function(sid){
      y = counts(x)[,clusters %in% ct & samples %in% sid]
      if(is.null(dim(y))){
        return(y/sum(y))
      }else{
        return(rowSums(y)/sum(y))
      }
    }), 1, var, na.rm = TRUE)
  })
  
  if(!is.null(select.ct)){
    m.ct = match(select.ct, colnames(Sigma))
    Sigma = Sigma[, m.ct]
  }
  
  if (!is.null(markers)){
    ids <- intersect(unlist(markers), rownames(x))
    m.ids = match(ids, rownames(x))
    Sigma <- Sigma[m.ids, ]
  }
  return(Sigma = Sigma)
}

#' Cell type specific library size
#'
#' This function is for calculating the cell type specific library size for selected cell types.
#'
#' @param x SingleCellExperiment, single cell dataset
#' @param non.zero logical, if true, remove all gene with zero expression
#' @param clusters character, the colData used as clusters
#' @param samples character,the colData used as samples
#' @param select.ct vector of cell types included, default as \code{NULL}. If \code{NULL}, include all cell types in \code{x}
#' @return subject by cell type matrix of library
#' @importFrom Matrix rowSums
#'
#' @export
music_S = function(x, non.zero, clusters, samples, select.ct){
  if(!is.null(select.ct)){
    x = x[, x@colData[, clusters] %in% select.ct]
  }
  if(non.zero){  ## eliminate non expressed genes
    x <- x[rowSums(counts(x))>0, ]
  }
  
  clusters <- as.character(colData(x)[, clusters])
  samples <- as.character(colData(x)[, samples])
  
  S <- sapply(unique(clusters), function(ct){
    my.rowMeans(sapply(unique(samples), function(sid){
      y = counts(x)[, clusters %in% ct & samples %in% sid]
      if(is.null(dim(y))){
        return(sum(y))
      }else{
        return(sum(y)/ncol(y))
      }
    }), na.rm = TRUE)
  })
  S[S == 0] = NA
  M.S = colMeans(S, na.rm = TRUE)
  
  if(!is.null(select.ct)){
    m.ct = match(select.ct, colnames(S))
    S = S[, m.ct]
  }
  return(S = S)
}

#' Cell type specific library size
#'
#' This function is for calculating the cell type specific library size for selected cell types.
#'
#' @inheritParams music_S
#' @inheritParams music_M.theta
#' @param x SingleCellExperiment, single cell dataset
#' @param non.zero logical, if true, remove all gene with zero expression
#' @param clusters character, the colData used as clusters
#' @param samples character,the colData used as samples
#' @param select.ct vector of cell types included, default as \code{NULL}. If \code{NULL}, include all cell types in \code{x}
#' @return subject by cell type matrix of library
#'
#' @export
#' @seealso
#' \code{\link{music_S}}, \code{\link{music_M.theta}},
music_Design.matrix = function(x, non.zero, markers, clusters, samples, select.ct){
  S = music_S(x = x, non.zero = non.zero, clusters = clusters, samples = samples, select.ct = select.ct)
  M.theta = music_M.theta(x = x, non.zero = non.zero, markers = markers, clusters = clusters, samples = samples,
                          select.ct = select.ct)
  S[S == 0] = NA
  M.S = colMeans(S, na.rm = TRUE)
  D <- t(t(M.theta)*M.S)
  return(D)
}

#' Prepare Design matrix and Cross-subject Variance for MuSiC Deconvolution
#'
#' This function is used for generating cell type specific cross-subject mean and variance for each gene. Cell type specific library size is also calcualted.
#'
#' @param x SingleCellExperiment, single cell dataset
#' @param non.zero logical, default as TRUE. If true, remove all gene with zero expression.
#' @param markers vector or list of gene names. Default as NULL. If NULL, then use all genes provided.
#' @param clusters character, the colData used as clusters;
#' @param samples character,the colData used as samples;
#' @param select.ct vector of cell types. Default as NULL. If NULL, then use all cell types provided.
#' @param cell_size data.frame of cell sizes. 1st column contains the names of cell types, 2nd column has the cell sizes per cell type. Default as NULL. If NULL, then estimate cell size from data.
#' @param ct.cov logical. If TRUE, use the covariance across cell types.
#' @param verbose logical, default as TRUE.
#' @return a list of
#'  \itemize{
#'     \item {gene by cell type matrix of Design matrix;}
#'     \item {subject by celltype matrix of Library size;}
#'     \item {vector of average library size for each cell type;}
#'     \item {gene by celltype matrix of average relative abundance;}
#'     \item {gene by celltype matrix of cross-subject variation.}
#'     }
#' @importFrom Matrix rowSums
#'
#' @export
music_basis = function(x, non.zero = TRUE, markers = NULL, clusters, samples, select.ct = NULL, cell_size = NULL, ct.cov = FALSE, verbose = TRUE){
  if(!is.null(select.ct)){
    x = x[, x@colData[, clusters] %in% select.ct]
  }
  if(non.zero){  ## eliminate non expressed genes
    x <- x[rowSums(counts(x))>0, ]
  }
  
  clusters <- as.character(colData(x)[, clusters])
  samples <- as.character(colData(x)[, samples])
  
  M.theta <- sapply(unique(clusters), function(ct){
    my.rowMeans(sapply(unique(samples), function(sid){
      y = counts(x)[,clusters %in% ct & samples %in% sid]
      if(is.null(dim(y))){
        return(y/sum(y))
      }else{
        return(rowSums(y)/sum(y))
      }
    }), na.rm = TRUE)
  })
  if(verbose){message("Creating Relative Abudance Matrix...")}
  if(ct.cov){
    nGenes = nrow(x);
    n.ct = length(unique(clusters));
    nSubs = length(unique(samples))
    
    Theta <- sapply(unique(clusters), function(ct){
      sapply(unique(samples), function(sid){
        y = counts(x)[,clusters %in% ct & samples %in% sid]
        if(is.null(dim(y))){
          return(y/sum(y))
        }else{
          return( rowSums(y)/sum(y) )
        }
      })
    })
    if(!is.null(select.ct)){
      m.ct = match(select.ct, colnames(Theta))
      Theta = Theta[, m.ct]
    }
    
    Sigma.ct = sapply(1:nGenes, function(g){
      sigma.temp = Theta[nGenes*(0:(nSubs - 1)) + g, ];
      Cov.temp = cov(sigma.temp)
      Cov.temp1 = cov(sigma.temp[rowSums(is.na(Theta[nGenes*(0:(nSubs - 1)) + 1, ])) == 0, ])
      Cov.temp[which(colSums(is.na(sigma.temp))>0), ] = Cov.temp1[which(colSums(is.na(sigma.temp))>0), ]
      Cov.temp[, which(colSums(is.na(sigma.temp))>0)] = Cov.temp1[, which(colSums(is.na(sigma.temp))>0)]
      return(Cov.temp)
    })
    colnames(Sigma.ct) = rownames(x);
    
    if (!is.null(markers)){
      ids <- intersect(unlist(markers), rownames(x))
      m.ids = match(ids, rownames(x))
      Sigma.ct <- Sigma.ct[ , m.ids]
    }
    if(verbose){message("Creating Covariance Matrix...")}
  }else{
    Sigma <- sapply(unique(clusters), function(ct){
      apply(sapply(unique(samples), function(sid){
        y = counts(x)[,clusters %in% ct & samples %in% sid]
        if(is.null(dim(y))){
          return(y/sum(y))
        }else{
          return(rowSums(y)/sum(y))
        }
      }), 1, var, na.rm = TRUE)
    })
    if(!is.null(select.ct)){
      m.ct = match(select.ct, colnames(Sigma))
      Sigma = Sigma[, m.ct]
    }
    
    if (!is.null(markers)){
      ids <- intersect(unlist(markers), rownames(x))
      m.ids = match(ids, rownames(x))
      Sigma <- Sigma[m.ids, ]
    }
    if(verbose){message("Creating Variance Matrix...")}
  }
  
  S <- sapply(unique(clusters), function(ct){
    my.rowMeans(sapply(unique(samples), function(sid){
      y = counts(x)[, clusters %in% ct & samples %in% sid]
      if(is.null(dim(y))){
        return(sum(y))
      }else{
        return(sum(y)/ncol(y))
      }
    }), na.rm = TRUE)
  })
  if(verbose){message("Creating Library Size Matrix...")}
  
  S[S == 0] = NA
  M.S = colMeans(S, na.rm = TRUE)
  #S.ra = relative.ab(S, by.col = FALSE)
  #S.ra[S.ra == 0] = NA
  #S[S == 0] = NA
  #M.S = mean(S, na.rm = TRUE)*ncol(S)*colMeans(S.ra, na.rm = TRUE)
  
  if(!is.null(cell_size)){
    if(!is.data.frame(cell_size)){
      stop("cell_size paramter should be a data.frame with 1st column for cell type names and 2nd column for cell sizes")
    }else if(sum(names(M.S) %in% cell_size[, 1]) != length(names(M.S))){
      stop("Cell type names in cell_size must match clusters")
    }else if (any(is.na(as.numeric(cell_size[, 2])))){
      stop("Cell sizes should all be numeric")
    }
    my_ms_names <- names(M.S)
    cell_size <- cell_size[my_ms_names %in% cell_size[, 1], ]
    M.S <- cell_size[match(my_ms_names, cell_size[, 1]),]
    M.S <- M.S[, 2]
    names(M.S) <- my_ms_names
  }
  
  D <- t(t(M.theta)*M.S)
  
  if(!is.null(select.ct)){
    m.ct = match(select.ct, colnames(D))
    D = D[, m.ct]
    S = S[, m.ct]
    M.S = M.S[m.ct]
    M.theta = M.theta[, m.ct]
  }
  
  if (!is.null(markers)){
    ids <- intersect(unlist(markers), rownames(x))
    m.ids = match(ids, rownames(x))
    D <- D[m.ids, ]
    M.theta <- M.theta[m.ids, ]
  }
  
  if(ct.cov){
    return(list(Disgn.mtx = D, S = S, M.S = M.S, M.theta = M.theta, Sigma.ct = Sigma.ct))
  }else{
    return(list(Disgn.mtx = D, S = S, M.S = M.S, M.theta = M.theta, Sigma = Sigma))
  }
}

