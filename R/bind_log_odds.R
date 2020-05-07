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
#' @references 1.Monroe, B. L., Colaresi, M. P. & Quinn, K. M. Fightin’ Words: Lexical Feature Selection and Evaluation for Identifying the Content of Political Conflict. Polit. anal. 16, 372–403 (2008).

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
#' gear_counts %>%
#'   bind_log_odds(vs, gear, n)
#'
#' @importFrom rlang enquo as_name is_empty sym
#' @importFrom dplyr count left_join mutate rename group_by ungroup group_vars
#' @export

bind_log_odds <- function(tbl, set, feature, n, unweighted = FALSE) {
    set <- enquo(set)
    feature <- enquo(feature)
    n_col <- enquo(n)

    ## groups are preserved but ignored
    grouping <- group_vars(tbl)
    tbl <- ungroup(tbl)

    # find alpha. for starts, assume alpha = 1

    pseudo <- tbl

    # allow alpha to vary by group
    # so alpha is a vector of pseudo counts to add to each
    # feature (word) count in each each group

    pseudo$alpha <- 1

    # word w, group i. assume only one topic, so omit k notation
    # !!n_col ~ y_wi
    pseudo <- mutate(pseudo, y_wi = !!n_col + alpha)

    # y_w ~ word count for word w across all groups
    # y_wi ~ word count for word w within group i
    feat_counts <- count(pseudo, !!feature, wt = y_wi)
    feat_counts <- rename(feat_counts, y_w = n)

    set_counts <- count(pseudo, !!set, wt = y_wi)
    set_counts <- rename(set_counts, n_i = n)

    pseudo_counts <- left_join(pseudo, feat_counts, by = as_name(feature))
    pseudo_counts <- left_join(pseudo_counts, set_counts, by = as_name(set))

    pseudo_counts

    # in `counts` the mapping to Monroe et al (2008) is as follows:
    #
    #   set ~ topic
    #   feature ~ word
    #
    #   n ~ y_{kw}^(i) -- count for word w in topic k for group i
    #   ??? ~ n_k -- total word count in topic k for all groups
    #   set_count ~ n_k^(i) -- total word count in topic k for group i
    #   set_count_other ~ n_k^(i) -- total word count in topic k for
    #                                  groups except i
    #   feat_count_other ~ n_k - y_{kw} -- total word count in topic k for
    #                                        groups except i

    # monroe paper notation: superscript is "group", w is word, k is topic

    # we have already inflated each word count by alpha, so you can ignore
    # the alpha terms in Monroe et al. i.e. the y_wi in `pseudo` is really
    # y_wi + alpha_wi in Monroe, but this is easier to follow

    results <- mutate(
        pseudo_counts,
        omega_wi = y_wi / (n_i - y_wi),
        omega_w = y_w / (sum(y_wi) - y_w),
        delta_wi = log(omega_wi) - log(omega_w),   # eqn 15,
        sigma2_wi = 1 / y_wi + 1 / y_w,            # eqn 18
        zeta_wi = delta_wi / sqrt(sigma2_wi)       # eqn 21
    )

    clean <- rename(
        results,
        log_odds = delta_wi,
        scaled_log_odds = zeta_wi
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

