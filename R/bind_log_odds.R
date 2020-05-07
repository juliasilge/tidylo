#' Bind the weighted log odds to a tidy dataset
#'
#' Calculate and bind the log odds ratio, weighted by a prior estimated from
#' the data itself via an empirical Bayesian approach, of a tidy dataset to the
#' dataset itself. The weighted log odds ratio is added as a column. This
#' functions supports non-standard evaluation through the tidyeval framework.
#'
#' @param tbl A tidy dataset with one row per feature and set.
#' @param set Column of sets between which to compare features, such as
#' documents for text data.
#' @param feature Column of features for identifying differences, such as words
#' or bigrams with text data.
#' @param n Column containing feature-set counts.
#' @param unweighted Return the unweighted log odds, in addition to the weighted
#' log odds computed via empirical Bayesian estimation. Defaults to `FALSE`.
#'
#' @details The arguments \code{set}, \code{feature}, and \code{n}
#' are passed by expression and support \link[rlang]{quasiquotation};
#' you can unquote strings and symbols. Grouping is preserved but ignored.
#'
#' The weighted log odds computed by this function are also z-scores for the
#' log odds; this quantity is useful for comparing frequencies across sets but
#' its relationship to an odds ratio is not straightforward after the weighting.
#'
#' The dataset must have exactly one row per set-feature combination for
#' this calculation to succeed. Read Monroe, Colaresi, and Quinn (2017) for
#' more on the weighted log odds ratio.
#'
#' @source <https://doi.org/10.1093/pan/mpn018>
#'
#' @references
#'  1. Monroe, B. L., Colaresi, M. P. & Quinn, K. M. Fightin’ Words: Lexical Feature Selection and Evaluation for Identifying the Content of Political Conflict. Polit. anal. 16, 372–403 (2008). <https://doi.org/10.1093/pan/mpn018>
#'
#'  2. Minka, T. P. Estimating a Dirichlet distribution. (2012). <https://tminka.github.io/papers/dirichlet/minka-dirichlet.pdf>
#'
#' @examples
#'
#' library(dplyr)
#'
#' gear_counts <- mtcars %>%
#'   count(vs, gear)
#'
#' gear_counts
#'
#' # find the number of gears most characteristic of each engine shape `vs`
#'
#' regularized <- gear_counts %>%
#'   bind_log_odds(vs, gear, n)
#'
#' # lo
#' regularized
#'
#' unregularized <- gear_counts %>%
#'   bind_log_odds(vs, gear, n, uninformative = TRUE)
#'
#' # these logs odd will be farther from zero
#' # than the regularized estimates!
#' unregularized
#'
#' # compare regularized and unregularized estimates
#'
#' labelled_regularized <- regularized %>%
#'   mutate(estimates = "regularized")
#'
#' labelled_unregularized <- unregularized %>%
#'   mutate(estimates = "unregularized")
#'
#' library(ggplot2)
#'
#' labelled_regularized %>%
#'   bind_rows(labelled_unregularized) %>%
#'   ggplot(aes(gear, scaled_log_odds)) +
#'   geom_point() +
#'   facet_wrap(~estimates)
#'
#' @importFrom rlang enquo as_name is_empty sym
#' @importFrom dplyr count left_join mutate rename group_by ungroup group_vars
#' @export

bind_log_odds <- function(tbl, set, feature, n, uninformative = FALSE) {
    set <- enquo(set)
    feature <- enquo(feature)
    n_col <- enquo(n)

    ## groups are preserved but ignored
    grouping <- group_vars(tbl)
    tbl <- ungroup(tbl)

    # the approach in the following is to choose a prior
    # alpha, then update the feature counts based on this prior,
    # generating psuedo counts. at this point, we do MLE computations
    # on the pseudo counts rather than working with a posterior
    # where we separately keep track of alpha

    pseudo <- tbl

    if (uninformative) {
        pseudo$alpha <- 1
    } else {

        # in this case we use an empirical bayes prior
        #
        # the MLE of a Dirichlet-Multinomial doesn't have a closed
        # form solution. instead we use a method of moments estimator
        # for the alpha that leverages the first moment of the
        # Dirichlet-Multinomial distribution

        # see https://tminka.github.io/papers/dirichlet/minka-dirichlet.pdf
        # for details on dirichlet-multinomial estimation

        # in practice, our pseudo-counts alpha will be the overall
        # word counts for each word

        # `.n` is the *actual count* of each word w across
        # all groups
        feat_counts <- count(pseudo, !!feature, wt = !!n_col)
        feat_counts <- rename(feat_counts, .n = n)
        feat_counts <- left_join(tbl, feat_counts, by = as_name(feature))

        pseudo$alpha <- feat_counts$.n
    }

    # note that Monroe et al (2018) considers multiple topics,
    # where the topic is denoted by a subscript k. in our case
    # we only ever have a single topic, and we omit the k notation
    #
    # the w subscript matches Monroe, the i subscript is a superscript
    # in Monroe
    #
    # note that we use feature ~ word, and set ~ group

    # y_wi is the pseudo count of word w in group i
    pseudo <- mutate(pseudo, y_wi = !!n_col + alpha)

    # y_w is the total count of word w
    feat_counts <- count(pseudo, !!feature, wt = y_wi)
    feat_counts <- rename(feat_counts, y_w = n)

    # n_i is the count of all words in group i
    set_counts <- count(pseudo, !!set, wt = y_wi)
    set_counts <- rename(set_counts, n_i = n)

    # merge the various counts together so we can
    # do vectorized operations in a data frame
    pseudo_counts <- left_join(pseudo, feat_counts, by = as_name(feature))
    pseudo_counts <- left_join(pseudo_counts, set_counts, by = as_name(set))

    # alphas omitted in the following since we working directly
    # with pseudocounts, rather than adding in the alphas at this
    # point. here we have no subscript k because we consider a single
    # topic

    results <- mutate(
        pseudo_counts,
        omega_wi = y_wi / (n_i - y_wi),            # odds in group i
        omega_w = y_w / (sum(y_wi) - y_w),         # overall odds
        delta_wi = log(omega_wi) - log(omega_w),   # eqn 15,
        sigma2_wi = 1 / y_wi + 1 / y_w,            # eqn 18
        zeta_wi = delta_wi / sqrt(sigma2_wi)       # eqn 21
    )

    clean <- rename(
        results,
        scaled_log_odds = zeta_wi,
        log_odds = delta_wi,
    )

    tbl <- select(
        clean,
        -y_wi, -y_w, -n_i, -omega_wi, -omega_w, -sigma2_wi
    )

    if (!is_empty(grouping))  {
        tbl <- group_by(tbl, !!sym(grouping))
    }

    tbl
}

