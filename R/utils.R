#' Utility functions
#'
#' @name utils
#' @include statsnbaR-package.R
#' @keywords internal
NULL

#' Named type conversion functions
#'
#' List of functions to parse data returned by stats.nba.com into (hopefully)
#' meaningul or intuitive R data types.
#'
#' @format A named list of type-conversion functions. Some of these
#' are standard functions such as as.integer, while others are
#' specified in source code, e.g.
#' \describe{
#'     \item{date}{convert using \code{as.Date()}}
#'     \item{last_name}{extract last name from 'lastname, firstname'}
#'     \item{first_name}{extract first name from 'lastname, firstname'}
#'     \item{...}{convert to data type corresponding to name}
#' }
#'
#' The source code can be found at
#' \url{http://www.github.com/stephematicina/statsnbaR/tree/master/R/utils.R}
type_converters = list(
    'api_date'=function(x) {
                   if (!is.null(x)) {
                       format(x, format='%d/%m/%Y')
                   } else NULL
               },
    'api_season'=function(x) {
                     if(is.numeric(x) &&
                        (x %% 1) == 0) {
                        year_start <- as.character(x)
                        year_end <- as.character(x+1)
                        paste0(year_start, '-', substr(year_end, 3, 4))
                     } else NULL
                 },
    'character'=as.character,
    'date'=function(x) {
               if (!is.null(attr(x, 'tzone'))) {
                 return(as.Date(x, tz=attr(x, 'tzone')))
               }
               as.Date(x)
             },
    'double'=as.double,
    'factor'=factor,
    'first_name'=function(x) {
                    sub('^(.*),[\\s]*(.*)$', '\\2', x, perl=TRUE)
                 },
    'hexmode'=function(x) {
                  if (!length(x)) {
                      return(character(0))
                  }
                  as.hexmode(x)
              },
    'integer'=as.integer,
    'last_name'=function(x) {
                    sub('^(.*),[\\s]*(.*)$', '\\1', x, perl=TRUE)
                 },
    'logical'=as.logical,
    'numeric'=as.numeric,
    'ordered'=ordered,
    'posix_date'=as.POSIXct
)

#' Validate key-value pairs as being statsnbaR-recognisable
#'
#' Validate key-value pairs as being statsnbaR-recognisable
#'
#' @param filters Named list of key-value pairs used internally by statsnbaR
#' @return Logical result of tests
#' @keywords internal
valid_filters <- function(filters) {
    
    is.list(filters) &&
    all(names(filters) %in% names(statsnbaR.ADL.filters)) &&
    all(sapply(filters,
               function(f) {
                   ((length(f)==1) && (is.numeric(f) ||
                                       is.character(f) ||
                                       is.logical(f))) ||
                   is.null(f)
                })) &&
    all(sapply(1:length(filters),
               function(j) {
                   name <- names(filters)[j]
                   mapping <- statsnbaR.ADL.filters[[name]]$mapping

                   ifelse(!is.null(mapping),
                          filters[[j]] %in% names(mapping),
                          TRUE)
               }))
}

#' Translate key-value pairs to the stats.nba.com API key-value pairs
#'
#' Translates the key-values in a named list of statsnbaR key-value pairs to
#' key-value pairs that the stats.nba.com API recognises for use in the
#' calls to \code{httr::GET} in \code{\link{api_scrape}}.
#'
#' The stats.nba.com API end-point description is given in the internal
#' YAML which provides the translation of keys that statsnbaR specifies
#' to keys that stats.nba.com recognises, e.g. \sQuote{league} in statsnbaR is
#' translated to \dQuote{LeagueID} for stats.nba.com in this example:
#' \preformatted{
#' endpoints :
#'     PlayerCommon :
#'          api.filters  :
#'              league       : "LeagueID"
#'              ...
#' }
#'
#' The values are mapped according to the filter mappings also specified
#' in the internal YAML data, e.g:
#' \preformatted{
#' filters :
#'     league :
#'         mapping : \{
#'             NBA      : "00",
#'             D-League : "20"
#'             \}
#'         default : NBA
#'     ...
#' }
#' Thus \sQuote{NBA} would be mapped to \dQuote{00}.
#'
#' #' @seealso \code{\link{map_filter_values}}
#'
#' @param filters The statsnbaR filter key-value pairs.
#' @param api.endpoint statsnbaR specification of the stats.nba.com API
#'   endpoint
#' @return Named list of statsnbaR key-values mapped to stats.nba.com API
#'   key-value pairs.
#' @keywords internal
map_filters <- function(filters,
                        api.endpoint) {

    api.filters <- map_filter_values(filters)

    names(api.filters) <- api.endpoint$api.filters[names(filters)]

    return(api.filters)
}

#' Translate values (only) to stats.nba.com API values
#'
#' Translates the \emph{values} in a named list of statsnbaR key-value pairs to
#' values that the stats.nba.com API recognises.
#'
#' The mappings for each filter are specified in the internal YAML data
#' which look, for example, like the following:
#' \preformatted{
#' filters :
#'     league :
#'         mapping : \{
#'             NBA      : "00",
#'             D-League : "20"
#'             \}
#'         default : NBA
#' }
#' When we say that only the \emph{value} is mapped, that means we do not
#' map the key-name \sQuote{league} to the key-name that stats.nba.com
#' expects. We simply map the value 'NBA' that statsnbaR accepts to the value
#' "00" that the stats.nba.com API expects. Simple, yes?
#'
#' @seealso \code{\link{map_filters}}
#'
#' @param filters The statsnbaR filter key-value pairs
#' @return Named list of key-values with \emph{values} mapped to stats.nba.com 
#'   API values
#' @keywords internal
map_filter_values <- function(filters) {

    # Only map values for which a mapping exists.
    mapped <- lapply(names(filters),
                     function(j) {
                         mapping <- statsnbaR.ADL.filters[[j]]$mapping
                         filter_class <- statsnbaR.ADL.filters[[j]]$class

                         tc <- type_converters[[filter_class]]
                         nv <- if (!is.null(mapping)) {
                                      mapping[[as.character(filters[[j]])]]
                               } else filters[[j]]
                         if (!is.null(nv)) {
                            tc(nv)
                         } else ''
                     })
    names(mapped) <- names(filters)

    return(mapped)
}

#' Check output of API matches basic format
#'
#' Check output of API matches basic format
#'
#' @param api_result The list returned by \code{content} applied to the
#'   result of a query of stats.nba.com
#' @return Logical result of tests
#' @keywords internal
valid_results <- function(api_result) {
    is.list(api_result) &&
    (length(names(api_result)) == 3) &&
    all(c('parameters', 'resource', 'resultSets') %in% names(api_result)) &&
    all(sapply(api_result$resultSets,
        function(f) {
            length(names(f)) == 3 &&
            names(f) %in% c('name', 'headers', 'rowSet')  &&
            class(f$rowSet) == 'list' &&
            all(sapply(f$rowSet,
                       function(rs) {
                           length(rs) == length(f$headers)
                       }))
        }))
}

#' Flatten JSON result sets
#'
#' Takes a list provided by JSON and flattens the rowSet element to a
#' data.frame.
#'
#' The list is flattended by forcing any NULL values to NA, and then
#' applying the unlist function. The data.frame is then returned with the
#' attribute names set to the headers specified in the JSON data.
#'
#' @seealso \code{\link{type_converters}} \code{\link{map_results}}
#' \code{\link{map_result_values}}
#' 
#' @param json_result A list returned by JSON containing the rowSet and headers 
#' @return A data.frame for the flattened JSON rowSet
#' @keywords internal
flatten_json_rowSet <- function(json_result) {
    a <- json_result$rowSet
    a <- lapply(a, 
                function(b) {
                    b[sapply(b, is.null)] <- NA
                    return(b)
                })
    a <- data.frame(matrix(unlist(a), nrow=length(a), byrow=TRUE),
                    stringsAsFactors=FALSE)
    names(a) <- tolower(unlist(json_result$headers))

    return(a)
}


#' Map flattened NBA API data to statsnbaR data
#'
#' This takes the data.frames returned by \code{\link{flatten_json_rowSet}}
#' and converts the attributes (columns) to the desired data types specified
#' by statsnbaR's internal YAML.
#'
#' The column name is used to identify the correct mapping and/or type
#' conversion function. The mappings and data types are specified in the
#' statsnbaR internal YAML data, available at
#' \url{https://www.github.com/stephematician/statsnbaR/tree/master/data-raw/ADL.yaml}
#'
#' The YAML specification of the data type might look as follows:
#' \preformatted{
#' data    :
#'     played :
#'         class   : logical
#'         mapping : \{
#'             'Y' : TRUE,    # played
#'             'N' : FALSE    # never played
#'             \}
#' }
#'
#' Now any column named \sQuote{played} would be mapped from the character
#' values to a logical TRUE or FALSE, and converted to the logical class
#' (a redundant step for this example).
#'
#' @seealso \code{\link{type_converters}} \code{\link{map_result_values}}
#'
#' @param df Flattened NBA API data
#' @param api.mapping The mapping from API data to statsnbaR data
#' @return The data frame with mapped values
#' @keywords internal
map_results <- function(df,
                        api.mapping) {

    ADL_df <- data.frame(df[, unlist(api.mapping)],
                         stringsAsFactors=FALSE)

    names(ADL_df) <- names(api.mapping)

    map_result_values(ADL_df)

}

#' Convert character data from stats.nba.com to statsnbaR 'useful' data types 
#' 
#' Convert all columns of a data.frame using the specified mapping and type
#' conversion function as per the internal YAML data.
#'
#' The YAML specification of the data type might look as follows:
#' \preformatted{
#' data    :
#'     played :
#'         class   : logical
#'         mapping : \{
#'             'Y' : TRUE,    # played
#'             'N' : FALSE    # never played
#'             \}
#' }
#'
#' Now any column named \sQuote{played} would be mapped from the character
#' values to a logical TRUE or FALSE, and converted to the logical class
#' (a redundant step for this example).
#'
#' @seealso \code{\link{type_converters}}
#'
#' @param df The flattened JSON data.frame from stats.nba.com with statsnbaR
#'   attribute names.
#' @return Data.frame of converted and mapped data.
#' @keywords internal
map_result_values <- function(df) {

    mapped_df <- data.frame()

    mapped_df <- do.call(cbind,
            lapply(names(df),
                   function(j) {
                       mapping <- statsnbaR.ADL.data[[j]]$mapping
                       tc <- type_converters[[statsnbaR.ADL.data[[j]]$class]]

                       nc <- df[,j]
                       if (!is.null(mapping))
                           nc <- mapping[as.character(nc)]
                       if (!is.null(tc))
                           nc <- tc(nc)
                       return(data.frame(nc,
                                         stringsAsFactors=FALSE))
                   })
            )

    names(mapped_df) <- names(df)

    return(mapped_df)
}



