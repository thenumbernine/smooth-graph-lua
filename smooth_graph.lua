#!/usr/bin/env lua
matrix = require 'matrix'
gnuplot = require 'gnuplot'
require 'ext'

--[[ all_distribution.txt already is in terms of the score
local fn = ... or 'all_distribution.txt'
local d = file[fn]:trim():split'\n':map(tonumber:nargs(1))
--]]

local fn, sigmaMax = ...

local usingstrs
local d = file[fn]:trim():split'\n'
:filter(function(l)
	return l:sub(1,1) ~= '#'
end)
:mapi(function(line,rowindex,desttable)
	local keystr, valuestr = line:split'%s+':unpack()
	local y = tonumber(keystr)
	if not y then 
		usingstrs = true
		y = keystr
		--error("couldn't interpret "..line) 
	else
		y = math.floor(y)
	end
	local value = valuestr and assert(tonumber(valuestr)) or 1
	desttable[y] = (desttable[y] or 0) + value
end)
local keys = d:keys():sort()
if usingstrs then
	d = keys:mapi(function(k,_,t)
		return d[k], #t+1 
	end)
	-- TODO in this case, remap the indexes back into the strings?
end
--local minx = d:keys():inf()
--local maxx = d:keys():sup()
--d = d:mapi(function(v,k) return v, k-minx+1 end)
--for i=1,table.maxn(d) do d[i] = d[i] or 0 end
--print(tolua(d))

local function gaussian(x, sigma) 
	return matrix.lambda({#x}, function(i) 
		if sigma==0 then return x[i] end 
		local sum,ksum=0,0 
		for j=1,#x do 
			local y = (i-j)/sigma 
			local k = math.exp(-y*y) 
			sum=sum+x[j]*k 
			ksum=ksum+k 
		end 
		return sum/math.max(ksum,1e-7) 
	end) 
end

sigmaMax = tonumber(sigmaMax) or 10
print('sigmaMax', sigmaMax)
local sigmas = range(0,1,.01):mapi(function(v) return sigmaMax * v end)

gnuplot(table(
	{
		persist=true,
		savedata='results.txt',
		savecmds='cmds.txt',
		xlabel='value', 
		ylabel='count', 
		cblabel='gaussian sigma', 
		style='data lines', 
		data=
			table{
				range(#d):mapi(function(i)
					return usingstrs and keys[i] or i
				end),
			}:append(
				sigmas:mapi(function(sigma) 
					return gaussian(d, sigma) 
				end)
			)
--		:append{
--			range(minx,maxx,(maxx-minx)/100),
--		}
	}, 
	sigmas:mapi(function(sigma,i) 
		return {
			using= 0 -- (#sigmas+1)
				..':'..(i+1)..':('..sigma..')',
			title='',
			palette=true,
		} 
	end)
))
