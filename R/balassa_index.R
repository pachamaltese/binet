#' Balassa Index
#'
#' @description \code{balassa_index()} computes the Balassa Index for a
#' bipartite relation between two disjoint sets X, the "source" or "from" side,
#' and Y, the "target" or "to" side.
#'
#' @details The current implementation follows
#' \insertCite{measuringcomplexity2015}{binet} to obtain a metric for
#' specialisation. In the context of international trade, if the Balassa Index
#' for a country-product pair is more than 1, it means that country is
#' specialized in that product.
#'
#' @return A data.frame with the Balassa Index.
#'
#' @param data (Type: data.frame, matrix or dgCMatrix) a dataset such as \code{galactic_federation}
#' or any arrangement.
#' @param source (Type: character) the column with the elements of set X.
#' By default this is set to \code{"source"}.
#' @param target (Type: character) the column with the elements of set Y.
#' By default this is set to \code{"target"}.
#' @param value (Type: character) the column with the binary expression for the
#' Balassa Index.
#' By default this is set to \code{"value"}.
#' @param discrete (Type: logical) whether converting the Balassa Index to
#' discrete (0/1) values. Anything below the specified cutoff is converted to 0
#' and 1 otherwise. By default this is set to \code{TRUE}.
#' @param cutoff (Type: numeric) the cutoff to use for discretization.
#' By default this is set to \code{1}.
#'
#' @importFrom Matrix Matrix rowSums colSums t
#'
#' @examples
#' balassa_index(
#'   data = galactic_federation,
#'   source = "planet",
#'   target = "product",
#'   value = "export_value"
#' )
#' @references
#' For more information see:
#'
#' \insertRef{measuringcomplexity2015}{binet}
#'
#' and the references therein.
#'
#' @keywords functions
#'
#' @export

balassa_index <- function(data, source = "source", target = "target", value = "value",
                          discrete = TRUE, cutoff = 1) {
  # sanity checks ----
  if (!any(class(data) %in% c("data.frame", "matrix", "dgCMatrix"))) {
    stop("'data' must be a data.frame, matrix or dgCMatrix")
  }

  if (!is.character(source) | !is.character(target) | !is.character(value)) {
    stop("'source', 'target' and 'value' must be of type character")
  }

  if (!is.logical(discrete)) {
    stop("'discrete' must be TRUE or FALSE")
  }

  if (!is.numeric(cutoff)) {
    stop("'cutoff' must be numeric")
  }

  if (any(class(data) %in% "data.frame")) {
    data <- source_target_aggregation(data, source, target, value)
    data <- dataframe_to_matrix(data, source, target, value)
  }

  if (class(data) == "matrix") {
    data <- Matrix(data, sparse = TRUE)
  }

  data <- t(t(data / rowSums(data)) / (colSums(data) / sum(data)))

  if (discrete == TRUE) {
    data[data < cutoff] <- 0
    data[data >= cutoff] <- 1
  }

  return(data)
}
