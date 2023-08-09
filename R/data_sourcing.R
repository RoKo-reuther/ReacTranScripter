
source_config <- function(config, reaction_db) {
    reaction_db <- readLines(reaction_db)
    config <- readLines(config)
    result <- yaml::read_yaml(text = c(reaction_db, config))
    return(result)
}


determineExpressions1_ConstantsReactionsGeneric_handler <- function(instance_object, instance_name, expressions, local_constant_count, reaction_count, calling_entry) {

    # Handles creating of expression list for activated reactions and required reaction constants and generic expressions

    type <- instance_object$type

    if ( type == "global_constant" ) {
        if ( is.null(expressions[[instance_name]]) ) {
            expressions[[instance_name]] <- instance_object
            expressions[[instance_name]]$type <- "00_constant"
        }

    } else if ( type == "local_constant" ) {
        codename <- paste0("k", 500 + local_constant_count)
        expressions[[codename]] <- instance_object
        expressions[[codename]]$type <- "00_constant"
        local_constant_count <- local_constant_count + 1

        expression_with_replaced_name <- gsub(paste0("!", instance_name, "!"), codename, expressions[[calling_entry]]$expr)
        expressions[[calling_entry]]$expr <- expression_with_replaced_name

        index <- which(names(expressions[[calling_entry]]$require) == instance_name)
        names(expressions[[calling_entry]]$require)[index] <- codename

    } else if (type == "generic") {
        if ( is.null(expressions[[instance_name]]) ) {
            expressions[[instance_name]] <- instance_object
            expressions[[instance_name]]$type <- "02_generic"

            for (dependency_name in names(instance_object$require)){
                dependency_object <- instance_object$require[[dependency_name]]
                returned <- determineExpressions1_ConstantsReactionsGeneric_handler(
                    instance_object = dependency_object,
                    instance_name = dependency_name,
                    expressions = expressions,
                    local_constant_count = local_constant_count,
                    reaction_count = reaction_count,
                    calling_entry = instance_name
                )
                expressions <- returned$expressions
                local_constant_count <- returned$local_constant_count
                reactions_count <- returned$reaction_count
            }
        }

    } else if ( type == "reaction" ) {
        if ( is.null(expressions[[instance_name]]) ) {
            codename <- paste0("R", reaction_count)
            expressions[[instance_name]] <- instance_object
            expressions[[instance_name]]$type <- "03_reaction"
            expressions[[instance_name]]$codename <- codename
            reaction_count <- reaction_count + 1

            for (dependency_name in names(instance_object$require)){
                dependency_object <- instance_object$require[[dependency_name]]
                returned <- determineExpressions1_ConstantsReactionsGeneric_handler(
                    instance_object = dependency_object,
                    instance_name = dependency_name,
                    expressions = expressions,
                    local_constant_count = local_constant_count,
                    reaction_count = reaction_count,
                    calling_entry = instance_name
                )
                expressions <- returned$expressions
                local_constant_count <- returned$local_constant_count
                reaction_count <- returned$reaction_count
            }
        } else {
            codename <- expressions[[instance_name]]$codename
        }

        if ( !is.na(calling_entry) ) {
            expression_with_replaced_name <- gsub(paste0("!", instance_name, "!"), codename, expressions[[calling_entry]]$expr)
            expressions[[calling_entry]]$expr <- expression_with_replaced_name
        }
    }

    return(list(expressions = expressions,
                local_constant_count = local_constant_count,
                reaction_count = reaction_count))
}

determineExpressions1_ConstantsReactionsGeneric <- function(raw_config) {

    # Initialises expressions-list with activated reactions and required reaction constants and generic expressions

    expressions_list <- list()

    local_constant_count <- 0
    reaction_count       <- 1

    for (reaction_name in names(raw_config$active_reactions)){
        reaction_object <- raw_config$active_reactions[[reaction_name]]
        returned <- determineExpressions1_ConstantsReactionsGeneric_handler(
            instance_object = reaction_object,
            instance_name = reaction_name,
            expressions = expressions_list,
            local_constant_count = local_constant_count,
            reaction_count = reaction_count,
            calling_entry = NA
        )
        expressions_list <- returned$expressions
        local_constant_count <- returned$local_constant_count
        reaction_count <- returned$reaction_count
    }

    return(expressions_list)
}

count_dependencies <- function(instance_object) {

    dependency_count <- length(instance_object$require)

    for (dependency in instance_object$require) {
        next_level_count <- count_dependencies(dependency)
        dependency_count <- dependency_count + next_level_count
    }

    return(dependency_count)
}

add_require_count <- function(expressions) {

    for (instance_name in names(expressions)){
        instance_object <- expressions[[instance_name]]
        require_count <- count_dependencies(instance_object)
        expressions[[instance_name]]$require_count <- require_count
    }

    return(expressions)
}

order_expressions <- function(expressions) {

    # order by name
    expressions <- expressions[base::order(base::names(expressions))]
    # order by number of dependencies and type
    require_count <- "require_count"
    type <- "type"
    expressions <- rlist::list.sort(expressions, require_count, type)

    return(expressions)
}

