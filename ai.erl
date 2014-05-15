#!/usr/bin/env escript

-module(ai).


main(Args) ->
    true = code:add_pathz(filename:dirname(escript:script_name())
                       ++ "/deps/jiffy/ebin"),
    test_input(Args),
    UserRepo = get_user_and_repo(Args),
    Maintainer = get_username(),
    Url = build_url(Maintainer, UserRepo),
    inets:start(),
    ssl:start(),
    R = httpc:request(get, {Url, [{"User-Agent", "Abandoned-issues-Erlang-Client"}]}, [], []),
    {ok, {{"HTTP/1.1", _, _}, _, Body}} = R,
    Json = jiffy:decode(Body),
    FilterUrl = build_issue_url(UserRepo),
    Urls = filter_urls(Json, FilterUrl),
    print_urls(Urls).

build_issue_url(UserRepo) ->
    "https://github.com/" ++ string:join(UserRepo, "/") ++ "/".

filter_urls(Json, FilterUrl) ->
    Issues = proplists:get_value(<<"items">>, element(1, Json)),
    Urls = lists:foldl(fun(Item, Urls) ->
        IssueUrl = proplists:get_value(<<"html_url">>, element(1, Item)),
        IssueAsString = binary_to_list(IssueUrl),
        FoundAt = string:str(IssueAsString, FilterUrl),
        if
            FoundAt =/= 0 ->
                lists:append([Urls, [IssueAsString]]);
            true ->
                lists:append([Urls, []])
        end
    end, [], Issues),
    Urls.

print_urls(Urls) ->
    lists:foreach(fun(Item) ->
        io:format(Item ++ "\n")
    end, Urls).

build_url(Maintainer, UserRepo) ->
    RootUrl = "https://api.github.com/search/issues",
    Query = build_query(Maintainer, UserRepo),
    lists:concat([RootUrl, Query]).

build_query(Maintainer, UserRepo) ->
    [User, Repo] = UserRepo,
    lists:concat(["?q=commenter:", Maintainer,
        "+state:open+user:", User, "+repo:", Repo]).

get_username() ->
    os:getenv("AI_GITHUB_USERNAME").

get_user_and_repo(Args) ->
    [UserRepo] = Args,
    string:tokens(UserRepo, "/").

print_help() ->
    io:format("\nUsage:\n"),
    io:format("$ ai $USERNAME/$REPO\n").

test_input(Args) ->
    UserRepo = lists:nth(1, Args),
    Tokens = string:tokens(UserRepo, "/"),
    if
        length(Tokens) =/= 2 ->
            print_help(),
            halt(1);
        true ->
            true
    end.
