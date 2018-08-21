% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(test_engine_get_set_props).
-compile(export_all).


-include_lib("eunit/include/eunit.hrl").


cet_default_props() ->
    {ok, {_App, Engine, _Extension}} = application:get_env(couch, test_engine),
    {ok, Db} = test_engine_util:create_db(),
    Node = node(),

    ?assertEqual(Engine, couch_db_engine:get_engine(Db)),
    ?assertEqual(0, couch_db_engine:get_doc_count(Db)),
    ?assertEqual(0, couch_db_engine:get_del_doc_count(Db)),
    ?assertEqual(true, is_list(couch_db_engine:get_size_info(Db))),
    ?assertEqual(true, is_integer(couch_db_engine:get_disk_version(Db))),
    ?assertEqual(0, couch_db_engine:get_update_seq(Db)),
    ?assertEqual(0, couch_db_engine:get_purge_seq(Db)),
    ?assertEqual([], couch_db_engine:get_last_purged(Db)),
    ?assertEqual([], couch_db_engine:get_security(Db)),
    ?assertEqual(1000, couch_db_engine:get_revs_limit(Db)),
    ?assertMatch(<<_:32/binary>>, couch_db_engine:get_uuid(Db)),
    ?assertEqual([{Node, 0}], couch_db_engine:get_epochs(Db)),
    ?assertEqual(0, couch_db_engine:get_compacted_seq(Db)).


-define(ADMIN_ONLY_SEC_PROPS, {[
    {<<"members">>, {[
        {<<"roles">>, [<<"_admin">>]}
    ]}},
    {<<"admins">>, {[
        {<<"roles">>, [<<"_admin">>]}
    ]}}
]}).


cet_admin_only_security() ->
    Config = [{"couchdb", "default_security", "admin_only"}],
    {ok, Db1} = test_engine_util:with_config(Config, fun() ->
        test_engine_util:create_db()
    end),

    ?assertEqual(?ADMIN_ONLY_SEC_PROPS, couch_db:get_security(Db1)),
    test_engine_util:shutdown_db(Db1),

    {ok, Db2} = couch_db:reopen(Db1),
    couch_log:error("~n~n~n~n~s -> ~s~n~n", [couch_db:name(Db1), couch_db:name(Db2)]),
    ?assertEqual(?ADMIN_ONLY_SEC_PROPS, couch_db:get_security(Db2)).


cet_set_security() ->
    SecProps = {[{<<"foo">>, <<"bar">>}]},
    check_prop_set(get_security, set_security, {[]}, SecProps).


cet_set_revs_limit() ->
    check_prop_set(get_revs_limit, set_revs_limit, 1000, 50).


check_prop_set(GetFun, SetFun, Default, Value) ->
    {ok, Db0} = test_engine_util:create_db(),

    ?assertEqual(Default, couch_db:GetFun(Db0)),
    ?assertMatch(ok, couch_db:SetFun(Db0, Value)),

    {ok, Db1} = couch_db:reopen(Db0),
    ?assertEqual(Value, couch_db:GetFun(Db1)),

    ?assertMatch({ok, _}, couch_db:ensure_full_commit(Db1)),
    test_engine_util:shutdown_db(Db1),

    {ok, Db2} = couch_db:reopen(Db1),
    ?assertEqual(Value, couch_db:GetFun(Db2)).
