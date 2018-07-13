local postgres = require('luasql.postgres').postgres()
sql_conn = assert(postgres:connect('postgresql://user:password@localhost/db_name'))

local redis = require('redis')
redis_conn = assert(redis.connect('localhost', 6379))
