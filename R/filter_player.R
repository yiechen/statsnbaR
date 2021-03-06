#' Filter constructors for player data
#'
#' @name filter_player
#' @include utils.R
#' @include statsnbaR-package.R
#' @keywords internal
NULL

#' Worker function to generate filters for a \sQuote{per player} data query.
#'
#' @description
#' \code{\link{filter_per_player}} and \code{\link{filter_per_player_clutch}}
#' are both essentially wrappers to this function which does the work.
#'
#' @details
#' Returns a named list of key-value pairs which are given either by the
#' arguments to the function, or by default values specified by statnbaR
#' internal YAML data. Ensures that all the filters specified have a value,
#' but performs no checks on the values themselves.
#'
#' @param endpoint List containing stats.nba.com API endpoint specification as
#'   given by statsnbaR YAML data.
#' @param ... List of key-value pairs to use as the filters argument of
#'   \code{\link{per_player_data}}
#'
#' @return A list of key-value pairs for passing to the per-player query
#'   functions
#'
#' @seealso \code{\link{per_player_data}} \code{\link{filter_per_player}} 
#'   \code{\link{filter_per_player_clutch}}
#' @keywords internal
#' @author Stephen Wade
filter_per_player_worker <- function(endpoint, ...) {

    in_filters   <- list(...)
    if ('measurement' %in% names(in_filters)) {
        stop(paste('[statsnbaR filter_per_player_worker] cannot specify',
                   '\'measurement\' as an argument to the filter constructor'))
    }
    if ('clutch' %in% names(in_filters)) {
        stop(paste('[statsnbaR filter_per_player_worker] cannot specify',
                   '\'clutch\' as an argument to the filter constructor'))
    }
    filter_names <- names(endpoint$api.filters)

    if (!all(names(in_filters) %in% filter_names)) {
        invalid_filters <- !(names(in_filters) %in% filter_names)
        stop(paste0('[statsnbaR filter_per_player] invalid filters (',
                    paste(names(in_filters)[invalid_filters],
                          collapse=', '),
                    ') specified for per player query.'))
                            
    }

    filters <- lapply(filter_names,
                      function(name) {
                          in_filter <- in_filters[[name]]
                          if (!is.null(in_filter)) {
                              in_filter
                          } else statsnbaR.ADL.filters[[name]]$default
                      })
    names(filters) <- filter_names

    return(filters)
}

#' Generate filters for a \sQuote{per player} data query.
#'
#' @description
#' Creates a list of key-value pairs from the supplied arguments for use in
#' \code{\link{per_player_data}}, and inserts default values for any filters
#' not specified in the arguments.
#'
#' @details
#' Returns a named list of key-value pairs which are given either by the
#' arguments to the function, or by default values specified by statnbaR
#' internal YAML data. Ensures that all the filters specified have been
#' assigned a value.
#'
#' @param ... List of key-value pairs to use as filters in a query to the
#'   per-player data endpoint of stats.nba.com. The recognised filters are
#'   described here with their default values indicated in brackets:
#' \describe{
#'     \item{college}{character - full name of college of player (all)}
#'     \item{conference}{character - conference of player: 'both', 'west',
#'       'east' ('both')}
#'     \item{country}{character - nationality of players (all)}
#'     \item{date_from}{date - include games from this date: (null)}
#'     \item{date_to}{date - include games until this date: (null)}
#'     \item{division}{character - division of players: 'all', 'atlantic',
#'       'central', 'north_west', 'pacific', 'south_east', 'south_west' ('all')}
#'     \item{draft_pick}{character - draft status of players: 'all',
#'       'first_round', 'second_round', 'first_pick', 'lottery' ('all')}
#'     \item{draft_year}{integer - year players were drafted: (null)}
#'     \item{experience}{character - experience level of players: 'all', 'rookie',
#'       'sophomore', 'veteran' ('all')}
#'     \item{game_segment}{character - segment of game included: 'full_game',
#'       'first_half', 'second_half', 'overtime' ('full_game')}
#'     \item{height_segment}{character - filter player heights, 'lt_six' means <
#'       six feet tall, while gte_six means >= six feet tall : 'all', 'lt_six',
#'       'gte_six', 'lt_six_four', 'gte_six_four', 'lt_six_seven',
#'       'gte_six_seven', 'lt_six_ten', 'gte_six_ten', 'lt_seven', 'gte_seven'
#'       ('all')}
#'     \item{last_n}{integer - number of last games to include up to 15 (null)}
#'     \item{league}{character - league of players: 'NBA', 'D-league' ('NBA')}
#'     \item{location}{character - select home or away games: 'both', 'home',
#'       'away', ('all')}
#'     \item{month}{character - three letter abbrevation of month of games
#'       to include: ('all')}
#'     \item{opponent_conference}{}
#'     \item{opponent_division}{}
#'     \item{opponent_team}{integer - team_id of game opponent: (null)}
#'     \item{playoff_round}{integer - playoff round to include, 0 is for regular
#'       season games, 1 is for the first round, 4 is the NBA finals (0)}
#'     \item{pace_adjust}{logical - pace adjustment? (FALSE)}
#'     \item{per}{character - units of return values: 'total', 'game', 
#'       'possessions_100', 'plays_100', 'possession', 'play', 'minute',
#'       'minutes_48', 'minutes_40', 'minutes_36', 'inverse_minutes' ('total')}
#'     \item{period}{integer - quarter to include 0 is all, or 1--4 for 
#'       individual quarters}
#'     \item{position}{character - position of players: 'all', 'center',
#'       'forward', 'guard' ('all')}
#'     \item{plus_minus}{logical - differential to overall values? (FALSE)}
#'     \item{rank}{logical - rank results? (FALSE)}
#'     \item{season}{numeric - integer year of season to retrieve, e.g. 2014 for
#'       the 2014-15 season}
#'     \item{season_segment}{character - games to include by season segment:
#'       'all', 'pre_allstar', 'post_allstar' ('all')}
#'     \item{season_type}{character - games to include by season type:
#'       'allstar', 'playoff', 'regular', 'preseason' ('regular')}
#'     \item{shot_clock}{character - shot clock values of plays to include,
#'       segmented into all values, then 24--22, 22--18, 18--15, 15--7, 4--7
#'       and 4--0 seconds and Off: 
#'       'all', 'super_early', 'very_early', 'early', 'average', 'late',
#'       'very_late', 'off' ('all')}
#'     \item{starting_status}{character - starting status of player in games:
#'        'all', 'bench', 'starter' ('all')}
#'     \item{team_id}{integer - id of team to include (0)}
#'     \item{weight_segment}{character - filter players weights 'lt_200' means <
#'       200 lbs while 'gte200' means >= 200lbs : 'all', 'lt_200',
#'       'gte_200', 'lt_225', 'gte_225', 'lt_250',
#'       'gte_250', 'lt_275', 'gte_275', 'lt_300', 'gte_300'
#'       ('all')}
#'     \item{win_loss}{character - win or loss filter: 'all', 'win', 'loss'
#'       ('all')}
#' }
#'
#' @return A list of key-value pairs for passing to the per-player data query
#'   function \code{\link{per_player_data}} with argument \code{clutch=FALSE}.
#'
#' @seealso \code{\link{per_player_data}}
filter_per_player <- function(...) {

    filter_per_player_worker(statsnbaR.ADL.endpoints$per_player_base,
                             ...)

}

#' Generate filters for a \sQuote{per player} data query.
#'
#' @description
#' Creates a list of key-value pairs from the supplied arguments for use in
#' \code{\link{per_player_data}} with argument \code{clutch=TRUE}; and inserts
#' default values for any filters not specified in the call to the function.
#'
#' @details
#' This function is the same as the \code{\link{filter_per_player}} function
#' with the addition of the filters to determine what \sQuote{clutch} time is.
#'
#' @param ... List of key-value pairs to use as filters in a query to the
#'   per-player data endpoint of stats.nba.com. The basix key-values are
#'   described in \code{\link{filter_per_player}}. The additional clutch-related
#'   key-value pairs are described here with default values indicated in
#'   brackets:
#'   \describe{
#'     \item{clutch_time}{Number of seconds left in game: 300, 240, ..., 60,
#'       30, 10 (300)}
#'     \item{lead}{Whether the team is ahead or behind (incl. tied): 'any',
#'       'ahead', 'behind' ('any')}
#'     \item{point_diff}{The size of the point differential: 1--5 (5)}
#'   }
#'
#' @examples \dontrun{
#'   fppc <- filter_per_player_clutch(league='NBA', clutch_time=300)
#'   ppd <- per_player_data(filters=fppc, clutch=TRUE)
#' }
#'
#' @return A list of key-value pairs for passing to the per-player data query
#'   function \code{\link{per_player_data}} with argument \code{clutch=TRUE}.
#'
#' @seealso \code{\link{per_player_data}} \code{\link{filter_per_player}}
filter_per_player_clutch <- function(...) {

    filter_per_player_worker(statsnbaR.ADL.endpoints$per_player_base_clutch,
                             ...)

}
