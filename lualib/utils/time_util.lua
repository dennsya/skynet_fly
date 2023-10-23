local skynet = require "skynet"

local math = math
local assert = assert
local os = os

local M = {
	--1分钟 
	MINUTE = 60,
	--1小时
	HOUR = 60 * 60,
	--1天
	DAY = 60 * 60 * 24,
}

local starttime
--整型的skynet_time 
function M.skynet_int_time()
	if not starttime then
		starttime = math.floor(skynet.starttime() * 100)
	end
	return skynet.now() + starttime
end

--秒时间戳
function M.time()
	return math.floor(M.skynet_int_time() / 100)
end

--当前日期
function M.date(time)
	time = time or M.time()
	return os.date("*t",M.time())
end

--适配当月最后一天
function M.month_last_day(date, day)
	local year = date.year
	local month = date.month
	date.day = day
	os.time(date)
	while date.day ~= day do
		day = day - 1
		date.day = day
		date.month = month
		date.year = year
		os.time(date)
	end
end

--获取某天某个时间点的时间戳
--比如昨天 8点12分50 参数就是 -1,8,12,50
--明天 0点0分0秒 就是 1，0，0，0
function M.day_time(day,hour,min,sec)
	assert(day)
	assert(hour >= 0 and hour <= 23,hour)
	assert(min >= 0 and min <= 59,min)
	assert(sec >= 0 and sec <= 59,sec)
  
	local sub_day_time = day * 86400
	local date = os.date("*t",M.time() + sub_day_time)
	date.hour = hour
	date.min = min
	date.sec = sec
	return os.time(date)
end

--每一分钟的第几秒时间戳
function M.every_min(sec)
	assert(sec >= 0 and sec <= 59)
	local cur_time = M.time()
	local cur_date = M.date(cur_time)
	cur_date.sec = sec
	local next_time = os.time(cur_date)
	if next_time > cur_time then
		--还没过
		return next_time
	else
		--过了
		return next_time + M.MINUTE
	end
end

--每一小时的第几分钟第几秒
function M.every_hour(min,sec)
	assert(sec >= 0 and sec <= 59)
	assert(min >= 0 and min <= 59)
	local cur_time = M.time()
	local cur_date = M.date(cur_time)
	cur_date.sec = sec
	cur_date.min = min
	local next_time = os.time(cur_date)
	if next_time > cur_time then
		return next_time
	else
		return next_time + M.HOUR
	end
end

--每一天的几点几分几秒
function M.every_day(hour,min,sec)
	assert(hour >= 0 and hour <= 23,hour)
	assert(min >= 0 and min <= 59,min)
	assert(sec >= 0 and sec <= 59,sec)
	local cur_time = M.time()
	local cur_date = M.date(cur_time)
	cur_date.sec = sec
	cur_date.min = min
	cur_date.hour = hour
	local next_time = os.time(cur_date)
	if next_time > cur_time then
		return next_time
	else
		return next_time + M.DAY
	end
end

--每一周的周几几点几分几秒
function M.every_week(wday,hour,min,sec)
	assert(wday >= 1 and wday <= 7)
	assert(hour >= 0 and hour <= 23,hour)
	assert(min >= 0 and min <= 59,min)
	assert(sec >= 0 and sec <= 59,sec)
	local cur_time = M.time()
	local cur_date = M.date(cur_time)
	cur_date.sec = sec
	cur_date.min = min
	cur_date.hour = hour

	local next_time = os.time(cur_date)
	for i = 1,7 do
		if cur_date.wday == wday and next_time > cur_time then
			break
		end
		cur_date.day = cur_date.day + 1
		next_time = os.time(cur_date)
	end
	return next_time
end

--每个月的第几天几时几分几秒
--如果单月没有该天，适配到最后一天
function M.every_month(day,hour,min,sec)
	assert(day >= 1 and day <= 31)
	assert(hour >= 0 and hour <= 23,hour)
	assert(min >= 0 and min <= 59,min)
	assert(sec >= 0 and sec <= 59,sec)
	local cur_time = M.time()
	local cur_date = M.date(cur_time)
	cur_date.day = day
	cur_date.hour = hour
	cur_date.min = min
	cur_date.sec = sec
	
	M.month_last_day(cur_date, day)
	local next_time = os.time(cur_date)
	if next_time > cur_time then
		return next_time
	else
		cur_date.month = cur_date.month + 1
		M.month_last_day(cur_date, day)
		return os.time(cur_date)
	end
end

--每一年的第几月第几天几时几分几秒
--如果单月没有该天，适配到最后一天
function M.every_year(month,day,hour,min,sec)
	assert(month >= 1 and month <= 12)
	assert(day >= 1 and day <= 31)
	assert(hour >= 0 and hour <= 23,hour)
	assert(min >= 0 and min <= 59,min)
	assert(sec >= 0 and sec <= 59,sec)
	local cur_time = M.time()
	local cur_date = M.date(cur_time)
	cur_date.month = month
	cur_date.day = day
	cur_date.hour = hour
	cur_date.min = min
	cur_date.sec = sec

	M.month_last_day(cur_date, day)
	local next_time = os.time(cur_date)

	if next_time > cur_time then
		return next_time
	else
		cur_date.year = cur_date.year + 1
		M.month_last_day(cur_date, day)
		return os.time(cur_date)
	end
end

--每一年的第几天几时几分几秒
function M.every_year_day(yday,hour,min,sec)
	assert(yday >= 1 and yday <= 366)
	assert(hour >= 0 and hour <= 23,hour)
	assert(min >= 0 and min <= 59,min)
	assert(sec >= 0 and sec <= 59,sec)
	local cur_time = M.time()
	local cur_date = M.date(cur_time)
	cur_date.hour = hour
	cur_date.min = min
	cur_date.sec = sec
	local next_time = os.time(cur_date)
	for i = cur_date.yday,366 * 2 do
		if cur_date.yday == yday and next_time > cur_time then
			break
		end
		cur_date.day = cur_date.day + 1
		next_time = os.time(cur_date)
	end

	return next_time
end

return M