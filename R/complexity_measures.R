#' Complexity Measures
#'
#' @description \code{complexity_measures()} computes different complexity
#' measures obtained from the Balassa Index or a binary (0/1) metric for a
#' bipartite relation between two disjoint sets X, the "source" or "from" side,
#' and Y, the "target" or "to" side.
#'
#' @details The current implementation follows
#' \insertCite{measuringcomplexity2015}{binet} to obtain different metrics
#' that account for diversification in bipartite relations.
#'
#' @return A list of four data frames. Two complexity indexes that are
#' ordering rankings for specialization and two aggregations (sums) of
#' the Balassa Index.
#'
#' @param balassa_index (Type: matrix or dgCMatrix) the output from
#' \code{balassa_index()}) or an equivalent arrangement.
#' @param method (Type: character) one of these methods: fitness,
#' reflections or eigenvalues. By default this is set to \code{"fitness"}.
#' @param iterations (Type: numeric) the number of iterations to use.
#' By default this is set to \code{20}.
#' @param extremality (Type: numeric) the parameter to use in the fitness
#' method. The other methods don't use this parameter.
#' By default this is set to \code{1}.
#'
#' @importFrom Matrix Matrix rowSums colSums t
#' @importFrom stats sd cor
#'
#' @examples
#' complexity_measures(balassa_index = binet_output$balassa_index)
#'
#' @references
#' For more information on this index see:
#'
#' \insertRef{measuringcomplexity2015}{binet}
#'
#' and the references therein.
#'
#' @keywords functions
#'
#' @export

complexity_measures <- function(balassa_index, method = "fitness", iterations = 20, extremality = 1) {
  # sanity checks ----
  if (class(balassa_index) != "dgCMatrix") {
    stop("'balassa_index' must be a dgCMatrix")
  }

  if (!(any(method %in% c("fitness", "reflections", "eigenvalues")) == TRUE)) {
    stop("'method' must be 'fitness', 'reflections' or 'eigenvalues'")
  }

  if (!is.integer(iterations)) {
    iterations <- as.integer(iterations)

    if (iterations < 2L) {
      stop("'iterations' must be integer and >= 2")
    }
  }

  # compute complexity measures ----
  # balassa_sum_x (kx0) and balassa_sum_y (ky0)
  kx0 <- rowSums(balassa_index)
  ky0 <- colSums(balassa_index)

  # reflections is defined as a function as these steps are also used for
  # eigenvalues method
  reflections <- function() {
    # create empty matrices
    kx <- Matrix(0,
                         nrow = length(kx0), ncol = iterations,
                         sparse = TRUE
    )

    ky <- Matrix(0,
                         nrow = length(ky0), ncol = iterations,
                         sparse = TRUE
    )

    # fill the first columns with kx0 and ky0 to start iterating
    kx[, 1] <- kx0
    ky[, 1] <- ky0

    # compute cols 2 to "no. of iterations" by iterating from col 1
    for (j in 2:ncol(kx)) {
      kx[, j] <- (balassa_index %*% ky[, (j - 1)]) * (1 / kx0)
      ky[, j] <- (t(balassa_index) %*% kx[, (j - 1)]) * (1 / ky0)
    }

    # xci is of odd order and normalized
    xci <- (kx[, iterations - 1] - mean(kx[, iterations - 1])) /
      sd(kx[, iterations - 1])

    # yci is of even order and normalized
    yci <- (ky[, iterations] - mean(ky[, iterations])) /
      sd(ky[, iterations])

    names(xci) <- rownames(balassa_index)
    names(yci) <- colnames(balassa_index)

    return(list(xci = xci, yci = yci))
  }

  if (method == "reflections") {
    reflections_output <- reflections()
    xci <- reflections_output$xci
    yci <- reflections_output$yci
  }

  if (method == "eigenvalues") {
    # to check if a sign correction is needed
    reflections_output <- reflections()
    xci_r <- reflections_output$xci
    yci_r <- reflections_output$yci

    # compute eigenvalues for xci
    xci <- eigen((balassa_index %*% (t(balassa_index) * (1 / ky0))) * (1 / kx0))
    xci <- Re(xci$vectors[, 2])

    # normalized xci
    xci <- (xci - mean(xci)) / sd(xci)
    names(xci) <- rownames(balassa_index)

    # correct xci sign when required
    if (isTRUE(cor(xci, xci_r, use = "pairwise.complete.obs") < 0)) {
      xci <- (-1) * xci
    }

    # compute eigenvalues for yci
    yci <- eigen((t(balassa_index) %*% (balassa_index * (1 / kx0))) * (1 / ky0))
    yci <- Re(yci$vectors[, 2])

    # normalized yci
    yci <- (yci - mean(yci)) / sd(yci)
    names(yci) <- colnames(balassa_index)

    # correct yci sign when required
    if (isTRUE(cor(yci, yci_r, use = "pairwise.complete.obs") < 0)) {
      yci <- (-1) * yci
    }
  }

  if (method == "fitness") {
    # create empty matrices
    kx <- Matrix(0,
                         nrow = length(kx0), ncol = iterations,
                         sparse = TRUE
    )

    ky <- Matrix(0,
                         nrow = length(ky0), ncol = iterations,
                         sparse = TRUE
    )

    # fill the first columns with kx0 and ky0 to start iterating
    kx[, 1] <- 1
    ky[, 1] <- 1

    # compute cols 2 to "no. of iterations" by iterating from col 1
    for (j in 2:ncol(kx)) {
      kx[, j] <- balassa_index %*% ky[, (j - 1)]

      kx[, j] <- kx[, j] / mean(kx[, j])

      ky[, j] <- 1 / (t(balassa_index) %*%
                        (1 / kx[, (j - 1)])^extremality)^(1 / extremality)

      ky[, j] <- ky[, j] / mean(ky[, j])
    }

    xci <- kx[, iterations]

    yci <- ky[, iterations]

    names(xci) <- rownames(balassa_index)

    names(yci) <- colnames(balassa_index)
  }

  return(
    list(
      complexity_index_source = xci,
      complexity_index_target = yci,
      balassa_sum_source = kx0,
      balassa_sum_target = ky0
    )
  )
}
