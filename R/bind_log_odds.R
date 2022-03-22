#' Bind the weighted log odds to a tidy dataset
#'
#' Calculate and bind posterior log odds ratios, assuming a
#' multinomial model with a Dirichlet prior. The Dirichlet prior
#' parameters are set using an empirical Bayes approach by default,
#' but an uninformative prior is also available. Assumes that data
#' is in a tidy format, and adds the weighted log odds ratio
#' as a column. Supports non-standard evaluation through the
#' tidyeval framework.
#'
#' @param tbl A tidy dataset with one row per `feature` and `set`.
#'
#' @param set Column of sets between which to compare features, such as
#'   documents for text data.
#'
#' @param feature Column of features for identifying differences, such as words
#'   or bigrams with text data.
#'
#' @param n Column containing feature-set counts.
#'
#' @param uninformative Whether or not to use an uninformative Dirichlet
#'   prior. Defaults to `FALSE`.
#'
#' @param unweighted Whether or not to return the unweighted log odds,
#'   in addition to the weighted log odds. Defaults to `FALSE`.
#'
#' @return The original tidy dataset with up to two additional columns.
#'
#'   - `weighted_log_odds`: The weighted posterior log odds ratio, where
#'     the odds ratio is for the feature distribution within that set versus
#'     all other sets. The weighting comes from variance-stabilization
#'     of the posterior.
#'
#'   - `log_odds` (optional, only returned if requested): The posterior
#'     log odds without variance stabilization.
#'
#' @details The arguments `set`, `feature`, and `n`
#' are passed by expression and support
#' \code{\link[rlang:nse-force]{rlang::quasiquotation}}; you can unquote strings
#' and symbols. Grouping is preserved but ignored.
#'
#' The default empirical Bayes prior inflates feature counts in each group
#' by total feature counts across all groups. This is like using a moment
#' based estimator for the parameters of the Dirichlet prior. Note that
#' empirical Bayes estimates perform well on average, but can have
#' some surprising properties. If you are uncomfortable with
#' empirical Bayes estimates, we suggest using the uninformative prior.
#'
#' The weighted log odds computed by this function are also z-scores for the
#' log odds; this quantity is useful for comparing frequencies across sets but
#' its relationship to an odds ratio is not straightforward after the weighting.
#'
#' The dataset must have exactly one row per set-feature combination for
#' this calculation to succeed. Read Monroe et al (2008) for
#' more on the weighted log odds ratio.
#'
#' @references
#'  1. Monroe, B. L., Colaresi, M. P. & Quinn, K. M. Fightin' Words: Lexical Feature Selection and Evaluation for Identifying the Content of Political Conflict. Polit. anal. 16, 372-403 (2008). \doi{10.1093/pan/mpn018}
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
#' regularized
#'
#' unregularized <- gear_counts %>%
#'   bind_log_odds(vs, gear, n, uninformative = TRUE, unweighted = TRUE)
#'
#' # these log odds will be farther from zero
#' # than the regularized estimates
#' unregularized
#'
#' @importFrom rlang enquo as_name is_empty sym
#' @importFrom dplyr count left_join mutate rename select group_by ungroup group_vars
#' @export

bind_log_odds <- function(tbl, set, feature, n, uninformative = FALSE,
                          unweighted = FALSE) {
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
        feat_counts <- count(pseudo, !!feature, wt = !!n_col, name = ".n")
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
    feat_counts <- count(pseudo, !!feature, wt = y_wi, name = "y_w")

    # n_i is the count of all words in group i
    set_counts <- count(pseudo, !!set, wt = y_wi, name = "n_i")

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
        log_odds_weighted = zeta_wi,
        log_odds = delta_wi,
    )

    tbl <- select(
        clean,
        -y_wi, -y_w, -n_i, -omega_wi, -omega_w, -sigma2_wi, -alpha
    )

    if (!unweighted) {
        tbl$log_odds <- NULL
    }

    if (!is_empty(grouping))  {
        tbl <- group_by(tbl, !!sym(grouping))
    }

    tbl
}

