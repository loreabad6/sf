sgbp = function(x, predicate, region.id, ncol, sparse = TRUE, remove_self = FALSE, 
				retain_unique = FALSE) {
	if (remove_self || retain_unique) {
		if (length(x) != ncol)
			stop("remove_self or retain_unique only work for square sparse matrices")
		x = if (retain_unique) # (includes doing remove_self)
				mapply(function(x, y) { x[x > y] }, x, seq_along(x), SIMPLIFY = FALSE)
			else # remove_self 
				mapply(setdiff, x, seq_along(x), SIMPLIFY = FALSE)
	}
	ret = structure(x,
		predicate = predicate,
		region.id = region.id,
		remove_self = remove_self,
		retain_unique = retain_unique,
		ncol = ncol,
		class = c("sgbp", "list"))
	if (! sparse)
		as.matrix(ret)
	else
		ret
}

#' Methods for dealing with sparse geometry binary predicate lists
#' 
#' Methods for dealing with sparse geometry binary predicate lists
#' @name sgbp
#' @export
#' @param x object of class \code{sgbp}
#' @param ... ignored
#' @param n integer; maximum number of items to print
#' @param max_nb integer; maximum number of neighbours to print for each item
#' @details \code{sgbp} are sparse matrices, stored as a list with integer vectors holding the ordered \code{TRUE} indices of each row. This means that for a dense, \eqn{m \times n}{m x n} matrix \code{Q} and a list \code{L}, if \code{Q[i,j]} is \code{TRUE} then \eqn{j} is an element of \code{L[[i]]}. Reversed: when \eqn{k} is the value of \code{L[[i]][j]}, then \code{Q[i,k]} is \code{TRUE}.
print.sgbp = function(x, ..., n = 10, max_nb = 10) {
	n = min(length(x), n)
	hd = paste0("Sparse geometry binary predicate list of length ", length(x), ", ",
	 	"where the predicate was `", attr(x, "predicate"), "'")
	if (isTRUE(attr(x, "retain_unique")))
		hd = paste0(hd, ", with retain_unique = TRUE")
	else if (isTRUE(attr(x, "remove_self")))
		hd = paste0(hd, ", with remove_self = TRUE")
	cat(strwrap(hd), sep = "\n")
	if (n < length(x))
		cat("first ", n, " elements:\n", sep = "")
	nbh = function(i, m) {
		X = x[[i]]
		end = if (length(X) > m) ", ..." else ""
		cat(" ", i, ": ", sep = "")
		if (length(X))
			cat(paste(head(X, m), collapse = ", "), end, "\n", sep = "")
		else
			cat("(empty)\n")
	}
	lapply(1:n, nbh, m = max_nb)
	invisible(x)
}

#' @name sgbp
#' @export
t.sgbp = function(x) {
	m = attr(x, "ncol")
	structure(sgbp(CPL_transpose_sparse_incidence(x, m),
		predicate = attr(x, "predicate"),
		region.id = as.character(1:m),
		ncol = length(x)),
		dim = NULL)
}

#' @name sgbp
#' @export
as.matrix.sgbp = function(x, ...) {
	nc = attr(x, "ncol")
	get_vec = function(x, n) { v = rep(FALSE, n); v[x] = TRUE; v }
	do.call(rbind, lapply(x, get_vec, n = nc))
}

#' @name sgbp
#' @export
dim.sgbp = function(x) {
	c(length(x), attr(x, "ncol"))
}

#' @name sgbp
#' @param e1 object of class `sgbp`
#' @param e2 object of class `sgbp`
#' @export
#' @details `==` compares only the dimension and index values, not the attributes of two `sgbp` object; use `identical` to check for equality of everything.
Ops.sgbp = function(e1, e2) {
	switch(.Generic, 
	   "!" = {
			nc = 1:attr(e1, "ncol")
			sgbp(lapply(e1, function(x) setdiff(nc, x)),
				predicate = paste0("!", attr(e1, "predicate")),
				region.id = attr(e1, "region.id"),
				ncol = attr(e1, "ncol"))
	   },
	   "==" = (length(e1) == length(e2)) && all(mapply(function(x,y) identical(x, y), e1, e2)), 
	   "!=" = return(!(e1 == e2)),
		stop("only operators !, == and != are supported for sgbp objects")
	)
}

#' @name sgbp
#' @export
as.data.frame.sgbp = function(x, ...) {
	data.frame(row.id = rep(seq_along(x), lengths(x)), col.id = unlist(x))
}

setOldClass("sgbp")

setAs("sgbp", "sparseMatrix", function(from) {
	if (! requireNamespace("Matrix", quietly = TRUE))
		stop("package Matrix required, please install it first")
	idx = as.data.frame(from)
	Matrix::sparseMatrix(i = idx$row.id, j = idx$col.id, x = 1)
})
