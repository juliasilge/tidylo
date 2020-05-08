context("Weighted log odds calculation")

suppressPackageStartupMessages(library(dplyr))

w <- tibble(
    document = rep(1:2, each = 5),
    word = c(
        "the", "quick", "brown", "fox", "jumped",
        "over", "the", "lazy", "brown", "dog"
    ),
    frequency = c(
        1, 1, 1, 1, 2,
        1, 1, 1, 1, 2
    )
)

test_that("Can calculate weighted log odds", {
    result <- w %>%
        bind_log_odds(document, word, frequency)

    expect_equal(
        select(w, document, word, frequency),
        select(result, document, word, frequency)
    )

    expect_is(result, "tbl_df")
    expect_is(result$log_odds_weighted, "numeric")
    expect_equal(ncol(result), 4)
    expect_equal(sum(result$log_odds_weighted[c(2, 4:6, 8, 10)] > 0), 6)

    # preserves but ignores groups
    result2 <- w %>%
        group_by(document) %>%
        bind_log_odds(document, word, frequency)

    expect_equal(length(groups(result2)), 1)
    expect_equal(as.character(groups(result2)[[1]]), "document")
})

test_that("Can get back unweighted log odds", {
    result <- w %>%
        bind_log_odds(document, word, frequency, unweighted = TRUE)

    expect_equal(
        select(w, document, word, frequency),
        select(result, document, word, frequency)
    )

    expect_is(result, "tbl_df")
    expect_is(result$log_odds, "numeric")
    expect_is(result$log_odds_weighted, "numeric")
    expect_equal(ncol(result), 5)
    expect_equal(sum(result$log_odds[c(2, 4:6, 8, 10)] > 0), 6)
})


test_that("Weighted log odds works when the feature is a number", {
    z <- dplyr::tibble(
        id = rep(c(2, 3), each = 3),
        word = c("an", "interesting", "text", "a", "boring", "text"),
        n = c(1, 1, 3, 1, 2, 1)
    )

    result <- bind_log_odds(z, id, word, n)
    expect_false(any(is.na(result)))
    expect_equal(sum(result$log_odds_weighted[1:5] > 0), 5)
    expect_lt(result$log_odds_weighted[6], 0)
})


test_that("Weighted log odds with tidyeval works", {

    w <- tibble(
        document = rep(1:2, each = 5),
        word = c(
            "the", "quick", "brown", "fox", "jumped",
            "over", "the", "lazy", "brown", "dog"
        ),
        frequency = c(
            1, 1, 1, 1, 2,
            1, 1, 1, 1, 2
        )
    )
    termvar <- quo(word)
    documentvar <- quo(document)
    countvar <- quo(frequency)

    result <- w %>%
        bind_log_odds(!!documentvar, !!termvar, !!countvar)

    termvar <- sym("word")
    documentvar <- sym("document")
    countvar <- sym("frequency")

    result2 <- w %>%
        bind_log_odds(!!documentvar, !!termvar, !!countvar)


    expect_equal(
        select(w, document, word, frequency),
        select(result, document, word, frequency)
    )

    expect_equal(
        select(w, document, word, frequency),
        select(result2, document, word, frequency)
    )

    expect_is(result, "tbl_df")
    expect_is(result$log_odds_weighted, "numeric")
    expect_equal(sum(result$log_odds_weighted[c(2, 4:6, 8, 10)] > 0), 6)

    result3 <- w %>%
        group_by(document) %>%
        bind_log_odds(!!documentvar, !!termvar, !!countvar)

    expect_equal(length(groups(result3)), 1)
    expect_equal(as.character(groups(result3)[[1]]), "document")
})
