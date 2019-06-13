#' Bind the weighted log odds to a tidy dataset
#'
#' Calculate and bind the log odds ratio, weighted by an uninformative Dirichlet
#' prior, of a tidy dataset to the dataset itself. The weighted log odds ratio
#' is added as a column. This functions supports non-standard evaluation through
#' the tidyeval framework.
#'
#' @param tbl A tidy dataset with one row per feature and set
#' @param feature Column of features for identifying differences, such as words or
#' bigrams with text data
#' @param set Column of sets between which to compare features, such as
#' documents for text data
#' @param n Column containing feature-set counts
#'
#' @details The arguments \code{feature}, \code{set}, and \code{n}
#' are passed by expression and support \link[rlang]{quasiquotation};
#' you can unquote strings and symbols. Grouping is preserved but ignored.
#'
#'
#' The dataset must have exactly one row per document-term combination for
#' this calculation to succeed. Read Monroe, Colaresi, and Quinn (2017) for
#' more on the weighted log odds ratio.
#'
#' @source <https://doi.org/10.1093/pan/mpn018>
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
#'   bind_log_odds(gear, vs, n)
#'
#' @importFrom rlang enquo as_name is_empty sym
#' @importFrom dplyr count left_join mutate rename group_by ungroup group_vars
#' @export

bind_log_odds <- function(tbl, feature, set, n) {
    feature <- enquo(feature)
    set <- enquo(set)
    n_col <- enquo(n)

    ## groups are preserved but ignored
    grouping <- group_vars(tbl)
    tbl <- ungroup(tbl)

    freq1_df <- count(tbl, !!feature, wt = !!n_col)
    freq1_df <- rename(freq1_df, freq1 = n)

    freq2_df <- count(tbl, !!set, wt = !!n_col)
    freq2_df <- rename(freq2_df, freq2 = n)

    df_joined <- left_join(tbl, freq1_df, by = as_name(feature))
    df_joined <- mutate(df_joined, freqnotthem = freq1 - !!n_col)
    df_joined <- mutate(df_joined, total = sum(!!n_col))
    df_joined <- left_join(df_joined, freq2_df, by = as_name(set))
    df_joined <- mutate(df_joined,
                        freq2notthem = total - freq2,
                        l1them = (!!n_col + freq1) / ((total + freq2) - (!!n_col + freq1)),
                        l2notthem = (freqnotthem + freq1) / ((total + freq2notthem) - (freqnotthem + freq1)),
                        sigma2 = 1/(!!n_col + freq1) + 1/(freqnotthem + freq1),
                        log_odds = (log(l1them) - log(l2notthem)) / sqrt(sigma2))

    tbl$log_odds <- df_joined$log_odds

    if (!is_empty(grouping))  {
        tbl <- group_by(tbl, !!sym(grouping))
        }

    tbl
}

